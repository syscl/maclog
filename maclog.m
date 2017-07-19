//
//  maclog.m
//  maclog
//
//  Created by lighting on 1/7/17.
//  Copyright (c) 2017 syscl. All rights reserved.
//
// This work is licensed under the Creative Commons Attribution-NonCommercial
// 4.0 Unported License => http://creativecommons.org/licenses/by-nc/4.0
//

//
// syscl::header files
//
#include "maclog.h"

//
// Generate time string
//
char *gTimeStr (size_t size, const char *fmt, ...) {
    char *str = calloc(size, sizeof(char));
    if (str == NULL) return NULL;

    va_list args;
    va_start(args, fmt);
    size_t printedChars = vsnprintf(str, size, fmt, args);
    if (printedChars <= 0 || printedChars >= size) {
        free(str);
        str = NULL;
    }
    va_end(args);

    return str;
}

//
// Modified from PowerManagement CommonLib.h `asl_object_t open_pm_asl_store()`
// https://opensource.apple.com/source/PowerManagement/PowerManagement-637.50.9/common/CommonLib.h.auto.html
// TODO: Sierra's PowerManager still uses the old ASL logging system, that's why we can do this.
// TODO: However I don't know if this will be the case on newer macOS versions.
// TODO: It would be great if someone with High Sierra (10.13), could test this and check if it still works.
//
asl_object_t searchPowerManagerASLStore(const char *key, const char *value)
{
    size_t endMessageID;
    asl_object_t list = asl_new(ASL_TYPE_LIST);
    asl_object_t response = NULL;

    if (list != NULL)
    {
        asl_object_t query = asl_new(ASL_TYPE_QUERY);
        if (query != NULL)
        {
            if (asl_set_query(query, key, value, ASL_QUERY_OP_EQUAL) == 0)
            {
                asl_append(list, query);
                asl_object_t pmStore = asl_open_path(kPMASLStorePath, 0);
                if (pmStore != NULL)
                {
                    response = asl_match(pmStore, list, &endMessageID, 0, 0, 0, ASL_MATCH_DIRECTION_FORWARD);
                }
                asl_release(pmStore);
            }
            asl_release(query);
        }
        asl_release(list);
    }

    return response;
}

//
// get current time
//
char *gCurTime(void)
{
    time_t gRawTime = time(NULL);
    struct tm *gTimeInf = localtime(&gRawTime);
    return gTimeStr(11, "%d-%d-%d", gTimeInf->tm_year + 1900, gTimeInf->tm_mon + 1, gTimeInf->tm_mday);
}

//
// Modified from https://stackoverflow.com/questions/3269321/osx-programmatically-get-uptime#answer-11676260
// get machine's lat boot time
//
char *gBootTime(void)
{
    struct timeval gBootTime;
    size_t len = sizeof(gBootTime);
    int mib[2] = {CTL_KERN, KERN_BOOTTIME};
    if (sysctl(mib, 2, &gBootTime, &len, NULL, 0) < 0) return NULL;
    struct tm *gTimeInf = localtime(&gBootTime.tv_sec);
    return gTimeStr(20, "%d-%d-%d %d:%d:%d",
            gTimeInf->tm_year + 1900,
            gTimeInf->tm_mon + 1,
            gTimeInf->tm_mday,
            gTimeInf->tm_hour,
            gTimeInf->tm_min,
            gTimeInf->tm_sec
    );
}

//
// get time of last powerManagement domain event
//
char *gPowerManagerDomainTime(const char *domain)
{
    asl_object_t logMessages = searchPowerManagerASLStore(kPMASLDomainKey, domain);

    // Get last message
    asl_reset_iteration(logMessages, SIZE_MAX);
    aslmsg last = asl_prev(logMessages);
    asl_release(logMessages);

    if (last == NULL) return NULL;

    long gMessageTime = atol(asl_get(last, ASL_KEY_TIME));
    struct tm *gTimeInf = localtime(&gMessageTime);
    asl_release(last);

    return gTimeStr(20, "%d-%d-%d %d:%d:%d",
            gTimeInf->tm_year + 1900,
            gTimeInf->tm_mon + 1,
            gTimeInf->tm_mday,
            gTimeInf->tm_hour,
            gTimeInf->tm_min,
            gTimeInf->tm_sec
    );
}

void printHelpAndExit (int exitStatus)
{
    printf(
            "USAGE: maclog [--version|-v] [--help|-h]\n"
            "USAGE: maclog [logMode] [-f|--filter=<query>]\n"
            "Arguments:\n"
            " --help,     -h  Show maclog help info.\n"
            " --version,  -v  Show maclog version info.\n"
            "Log Modes:\n"
            " --boot,     -b  Show log messages since last boot time.\n"
            " --darkWake, -d  Show log messages since last darkWake time.\n"
            " --sleep,    -s  Show log messages since last sleep time.\n"
            " --stream,   -S  Show log messages in real time.\n"
            " --wake,     -w  Show log messages since last wake time.\n"
            "Filter:\n"
            " --filter,   -f  Show log messages filtered by the <query>.\n"
            "NOTE: The default behaviour is to show all log messages of the current day.\n"
            "NOTE: The messages returned by \e[1m--boot\e[0m, \e[1m--sleep\e[0m, "
            "\e[1m--wake\e[0m, \e[1m--darkWake\e[0m can be from previous days,"
            " depending on the last time each action occurred.\n"
    );
    exit(exitStatus);
}

int killProcess (pid_t pid, ppath_t ppath, int signal) {
    if (kill(pid, 0) == 0) {
        ppath_t checkProcessPath = {0};
        if (proc_pidpath(pid, checkProcessPath, sizeof(ppath_t)) > 0 &&
            strcmp(ppath, checkProcessPath) == 0)
        {
            kill(pid, signal);
            return 0;
        }
    }

    return -1;
}

void signalHandler(int sig, siginfo_t *info, void *ucontext)
{
    int exitCode = EXIT_FAILURE;
    if (sig == SIGUSR1)
    {
        sleep(1);
        pid_t pid = fork();
        pid_t logPid = info->si_pid;
        ppath_t ppath = {0};
        if (kill(logPid, 0) == 0 && proc_pidpath(logPid, ppath, sizeof(ppath_t)) > 0)
        {
            if (pid == 0)
            {
                // Child process will continue and wait till console is closed so it can cleanup any remaining process
                int consoleProcessId;
                if (access(gLogPath, F_OK) == 0 &&
                    posix_spawn(&consoleProcessId, gOpenf[0], NULL, NULL, gOpenf, environ) == 0 &&
                    waitpid(consoleProcessId, NULL, 0) != -1)
                {
                    exitCode = EXIT_SUCCESS;
                }
            }
            else if (pid > 0)
            {
                // Parent process should exit to release shell
                exit(EXIT_SUCCESS);
            }
        }

        killProcess(logPid, ppath, SIGINT);
        unlink(gLogPath);
    }

    exit(exitCode);
}

int main(int argc, char **argv)
{
    pid_t pid = fork();
    if (pid == 0)
    {
        //
        // child process
        //
        int mode = 0;
        int filterFlag = 0;
        int optionIndex = 0;
        int currentOption = getopt_long(argc, argv, shortOptions, longOptions, &optionIndex);

        //
        // Handle arguments
        //
        while (currentOption != -1)
        {
            switch (currentOption)
            {
                case 'f':
                    if (filterFlag)
                    {
                        // Cleanup
                        free(gLogArgs[gLogFilter]);
                        // Log error
                        printf("ERROR: Filter argument should only appear once.\n");
                        exit(EXIT_FAILURE);
                    }

                    filterFlag = 1;
                    gLogArgs[gLogFilter] = calloc(sizeof(predicate filterConcat) + strlen(optarg), sizeof(char));
                    if (gLogArgs[gLogFilter] == NULL)
                    {
                        // Log error
                        printf("ERROR: Failed to allocate memory.\n");
                        exit(EXIT_FAILURE);
                    }

                    sprintf(gLogArgs[gLogFilter], predicate filterConcat "%s", optarg);
                    break;
                case 'v':
                    if (filterFlag) free(gLogArgs[gLogFilter]); // Cleanup
                    printf("v%.1f (c) 2017 syscl/lighting/Yating Zhou\n", PROGRAM_VER);
                    exit(EXIT_SUCCESS);
                default:
                    if (mode == 0)
                    {
                        mode = currentOption;
                        break;
                    }

                    // Log error
                    printf("ERROR: Different modes can't be mixed.\n");
                case 'h': case '?':
                    if (filterFlag) free(gLogArgs[gLogFilter]); // Cleanup
                    printHelpAndExit(EXIT_FAILURE);
            }

            currentOption = getopt_long(argc, argv, shortOptions, longOptions, &optionIndex);
        }

        //
        // Handle modes
        //
        if (mode == 'S') // Stream mode
        {
            gLogArgs[gLogCommand] = "stream";
            gLogArgs[7] = "--level";
            gLogArgs[8] = "info";
        }
        else // Normal modes
        {
            gLogArgs[gLogCommand] = "show";
            gLogArgs[7] = "--info";
            gLogArgs[8] = "--start";

            switch (mode)
            {
                case 0:
                    gLogArgs[gLogTime] = gCurTime();
                    break;
                case 'b':
                    gLogArgs[gLogTime] = gBootTime();
                    break;
                case 'd':
                    gLogArgs[gLogTime] = gPowerManagerDomainTime(kPMASLDomainPMDarkWake);
                    break;
                case 's':
                    gLogArgs[gLogTime] = gPowerManagerDomainTime(kPMASLDomainPMSleep);
                    break;
                case 'w':
                    gLogArgs[gLogTime] = gPowerManagerDomainTime(kPMASLDomainPMWake);
                    break;
            }

            if (gLogArgs[gLogTime] == NULL)
            {
                // Cleanup
                if (filterFlag) free(gLogArgs[gLogFilter]);
                // Log error
                printf(
                    "ERROR: Failed to retrieve log for requested mode: %c, Check `--help` to see if it is supported\n",
                    mode
                );
                exit(EXIT_FAILURE);
            }
        }

        //
        // create the log file
        //
        int fd = open(gLogPath, O_CREAT | O_TRUNC | O_RDWR, PERMS);

        //
        // get parent process id
        //
        pid_t ppid = getppid();

        if (fd < 0 ||
            ppid == 1 ||
            close(STDOUT_FILENO) < 0 ||
            dup2(fd, STDOUT_FILENO) < 0 || // redirect output to log file
            kill(ppid, SIGUSR1) < 0 || // signal parent to open Console.app
            execvp(gLogArgs[0], gLogArgs) < 0) // call system log
        {
            // Cleanup
            unlink(gLogPath);
            free(gLogArgs[gLogTime]);
            if (filterFlag) free(gLogArgs[gLogFilter]);
            // Log error
            printf("ERROR: Failed to redirect logs.\n");
            // Close parent
            exit(EXIT_FAILURE);
        }
    }
    else if (pid > 0)
    {
        //
        // parent process
        //

        //
        // register signal handler
        //
        struct sigaction act = {
                .sa_sigaction = signalHandler,
                .sa_flags = SA_SIGINFO
        };
        if (sigemptyset (&act.sa_mask) < 0 || sigaction (SIGUSR1, &act, NULL) < 0) {
            printf("ERROR: Parent process can't register signal handler\n");
            exit(EXIT_FAILURE);
        }

        //
        // wait children in case something goes wrong
        //
        int status;
        if (waitpid(pid, &status, 0) == -1 || WIFEXITED(status) == 0 || WEXITSTATUS(status) != EXIT_SUCCESS)
        {
            exit(EXIT_FAILURE);
        }
    }
    else
    {
        //
        // fork failed
        //
        printf("ERROR: Fork failed\n");
        return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}
