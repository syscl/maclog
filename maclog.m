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

char *gCurTime(void)
{
    time_t gRawTime = time(NULL);
    struct tm *gTimeInf = localtime(&gRawTime);
    char *gTime = calloc(11, sizeof(char));
    if (gTime != NULL)
    {
        sprintf(
                gTime,
                "%d-%d-%d",
                gTimeInf->tm_year + 1900,
                gTimeInf->tm_mon + 1,
                gTimeInf->tm_mday
        );
    }
    return gTime;
}

//
// Modified from https://stackoverflow.com/questions/3269321/osx-programmatically-get-uptime#answer-11676260
//
char *gBootTime(void)
{
    struct timeval gBootTime;

    size_t len = sizeof(gBootTime);
    int mib[2] = {CTL_KERN, KERN_BOOTTIME};
    if (sysctl(mib, 2, &gBootTime, &len, NULL, 0) < 0)
    {
        printf("Failed to retrieve boot time.\n");
        exit(EXIT_FAILURE);
    }

    char *gTime = calloc(20, sizeof(char));
    struct tm *gTimeInf = localtime(&gBootTime.tv_sec);
    if (gTime != NULL)
    {
        sprintf(
                gTime,
                "%d-%d-%d %d:%d:%d",
                gTimeInf->tm_year + 1900,
                gTimeInf->tm_mon + 1,
                gTimeInf->tm_mday,
                gTimeInf->tm_hour,
                gTimeInf->tm_min,
                gTimeInf->tm_sec
        );
    }
    return gTime;
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

char *gPowerManagerDomainTime(const char *domain)
{
    asl_object_t logMessages = searchPowerManagerASLStore(kPMASLDomainKey, domain);

    // Get last message
    asl_reset_iteration(logMessages, SIZE_MAX);
    aslmsg last = asl_prev(logMessages);
    asl_release(logMessages);

    if (last == NULL)
    {
        printf("Failed to retrieve %s time.\n", domain);
        exit(EXIT_FAILURE);
    }

    long gMessageTime = atol(asl_get(last, ASL_KEY_TIME));
    struct tm *gTimeInf = localtime(&gMessageTime);
    asl_release(last);

    char *gTime = calloc(20, sizeof(char));

    if (gTime != NULL)
    {
        sprintf(
                gTime,
                "%d-%d-%d %d:%d:%d",
                gTimeInf->tm_year + 1900,
                gTimeInf->tm_mon + 1,
                gTimeInf->tm_mday,
                gTimeInf->tm_hour,
                gTimeInf->tm_min,
                gTimeInf->tm_sec
        );
    }
    return gTime;
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

void signalHandler(int signo)
{
    if (signo == SIGUSR1 && access(gLogPath, F_OK) == 0) execvp(gOpenf[0], gOpenf);
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
                case 'h':
                    if (filterFlag) free(gLogArgs[gLogFilter]); // Cleanup
                    printHelpAndExit(EXIT_SUCCESS);
                case 'v':
                    if (filterFlag) free(gLogArgs[gLogFilter]); // Cleanup
                    printf("v%.1f (c) 2017 syscl/lighting/Yating Zhou\n", PROGRAM_VER);
                    exit(EXIT_SUCCESS);
                case '?':
                    if (filterFlag) free(gLogArgs[gLogFilter]); // Cleanup
                    printHelpAndExit(EXIT_FAILURE);
                default:
                    if (mode)
                    {
                        // Cleanup
                        if (filterFlag) free(gLogArgs[gLogFilter]);
                        // Log error
                        printf("ERROR: Different modes can't be mixed.\n");
                        printHelpAndExit(EXIT_FAILURE);
                    }

                    mode = currentOption;
                    break;
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
                default:
                    // Cleanup
                    if (filterFlag) free(gLogArgs[gLogFilter]);
                    // Log error
                    printf("ERROR: Invalid mode: %c\n", mode);
                    printHelpAndExit(EXIT_FAILURE);
            }

            if (gLogArgs[gLogTime] == NULL)
            {
                // Cleanup
                if (filterFlag) free(gLogArgs[gLogFilter]);
                // Log error
                printf("ERROR: Failed to retrieve requested mode logs");
                exit(EXIT_FAILURE);
            }
        }

        //
        // create the log file
        //
        int fd = open(gLogPath, O_CREAT | O_TRUNC | O_RDWR, PERMS);

        //
        // redirect output to log file
        //
        if (fd < 0 || close(STDOUT_FILENO) < 0 || dup2(fd, STDOUT_FILENO) < 0)
        {
            // Cleanup
            if (filterFlag) free(gLogArgs[gLogFilter]);
            if(access(gLogPath, F_OK) == 0) unlink(gLogPath);
            free(gLogArgs[gLogTime]);
            // Log error
            printf("ERROR: Failed to redirect logs.\n");
            exit(EXIT_FAILURE);
        }

        //
        // signal parent to open console
        //
        int ppid = getppid();
        if (ppid == 1 || kill(ppid, SIGUSR1) < 0)
        {
            // Cleanup
            if (filterFlag) free(gLogArgs[gLogFilter]);
            if(access(gLogPath, F_OK) == 0) unlink(gLogPath);
            free(gLogArgs[gLogTime]);
            // Log error
            printf("ERROR: Failed to signal parent.\n");
            exit(EXIT_FAILURE);
        }

        //
        // call system log
        //
        if (execvp(gLogArgs[0], gLogArgs) < 0)
        {
            // Cleanup
            if (filterFlag) free(gLogArgs[gLogFilter]);
            if(access(gLogPath, F_OK) == 0) unlink(gLogPath);
            free(gLogArgs[gLogTime]);
            // Log error
            printf("ERROR: Failed to redirect logs.\n");
            // Close parent
            kill(SIGINT, ppid);
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
        if (signal(SIGUSR1, signalHandler) == SIG_ERR) {
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
