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
    char *gTime = calloc(11, sizeof(char));
    time_t gRawTime = time(NULL);
    struct tm *gTimeInf = localtime(&gRawTime);
    sprintf(
            gTime,
            "%d-%d-%d",
            gTimeInf->tm_year + 1900,
            gTimeInf->tm_mon + 1,
            gTimeInf->tm_mday
    );
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

    if (last == NULL) {
        printf("Failed to retrieve %s time.\n", domain);
        exit(EXIT_FAILURE);
    }

    long gMessageTime = atol(asl_get(last, ASL_KEY_TIME));
    struct tm *gTimeInf = localtime(&gMessageTime);

    char *gTime = calloc(20, sizeof(char));
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
    return gTime;
}

void prepareLogArgv(int type) {
    switch (type) {
        case showLogArgv:
            gLogArgs[gLogCommand] = "show";
            gLogArgs[7] = "--info";
            gLogArgs[8] = "--start";
            break;
        case streamLogArgv:
            gLogArgs[gLogCommand] = "stream";
            gLogArgs[7] = "--level";
            gLogArgs[8] = "info";
            break;
        default:
            printf("Failed to retrieve logs.\n");
            exit(EXIT_FAILURE);
    }
}

int main(int argc, char **argv)
{
    pid_t rc;
    char default_str[] = "(process == \"kernel\" OR eventMessage CONTAINS[c] \"kernel\")";
    char filter_str[]  = " AND eventMessage CONTAINS[c] \"";
    if ((rc = fork()) > 0)
    {
        //
        // parent process
        //
        
        //
        // create the log file
        //
        int fd = open(gLogPath, O_CREAT | O_TRUNC | O_RDWR, PERMS);
        
        //
        // Handle arguments
        //
        
        //
        // get filter
        //
        switch (argc) {
            case 3:
                if (strcmp(argv[1], "--filter") == 0 || strcmp(argv[1], "-f") == 0) {
                    gLogArgs[gLogFilter] = (char *)malloc(sizeof(char) * 2 + sizeof(default_str) + sizeof(filter_str) + sizeof(argv[2]));
                    sprintf(gLogArgs[gLogFilter], "%s%s%s\"", default_str, filter_str, argv[2]);
                }
                break;
            case 4:
                if (strcmp(argv[2], "--filter") == 0 || strcmp(argv[2], "-f") == 0) {
                    gLogArgs[gLogFilter] = (char *)malloc(sizeof(char) * 2 + sizeof(default_str) + sizeof(filter_str) + sizeof(argv[3]));
                    sprintf(gLogArgs[gLogFilter], "%s%s%s\"", default_str, filter_str, argv[3]);
                }
                break;
            default:
                gLogArgs[gLogFilter] = default_str;
                break;
        }
        //
        // get option
        //
        if (argc > 1)
        {
            if (strcmp(argv[1], "--stream") == 0 || strcmp(argv[1], "-S") == 0) {
                prepareLogArgv(streamLogArgv);
            } else {
                prepareLogArgv(showLogArgv);
                if (strcmp(argv[1], "--boot") == 0 || strcmp(argv[1], "-b") == 0)
                {
                    gLogArgs[gLogTime] = gBootTime();
                }
                else if (strcmp(argv[1], "--sleep") == 0 || strcmp(argv[1], "-s") == 0)
                {
                    gLogArgs[gLogTime] = gPowerManagerDomainTime(kPMASLDomainPMSleep);
                    
//                    for(int i=0; i<11; i++) printf("%s, ", gLogArgs[i]);
//                    return EXIT_SUCCESS;
                }
                else if (strcmp(argv[1], "--wake") == 0 || strcmp(argv[1], "-w") == 0)
                {
                    gLogArgs[gLogTime] = gPowerManagerDomainTime(kPMASLDomainPMWake);
                }
                else if (strcmp(argv[1], "--darkWake") == 0 || strcmp(argv[1], "-d") == 0)
                {
                    gLogArgs[gLogTime] = gPowerManagerDomainTime(kPMASLDomainPMDarkWake);
                }
                else if(strcmp(argv[1], "--version") == 0 || strcmp(argv[1], "-v") == 0){
                    if(access(gLogPath, F_OK) == 0) unlink(gLogPath);
                    printf("v%.1f (c) 2017 syscl/lighting/Yating Zhou\n", PROGRAM_VER);
                    exit(EXIT_SUCCESS);
                }
                else
                {
                    // TODO: need more improvement, sorry for being so lazy!
                    if(argc != 3 && argc != 4){
                        if(access(gLogPath, F_OK) == 0) unlink(gLogPath);
                        printf(
                               "Invalid argument(s).\n"
                               "USAGE: maclog [option] [-f|--filter <query>]\n"
                               " --boot, -b     Show log messages since last boot time.\n"
                               " --darkWake, -d Show log messages since last darkWake time.\n"
                               " --filter, -f   Show log messages filtered by the <query>.\n"
                               " --stream, -S   Show log messages in real time.\n"
                               " --sleep, -s    Show log messages since last sleep time.\n"
                               " --version, -v  Show this maclog version info.\n\n"
                               " --wake, -w     Show log messages since last wake time.\n"
                               "NOTE: The default behaviour is to show all log messages of the current day.\n"
                               "NOTE: The messages returned by \e[1m--boot\e[0m, \e[1m--sleep\e[0m, "
                               "\e[1m--wake\e[0m, \e[1m--darkWake\e[0m can be from previous days,"
                               " depending on the last time each action occurred.\n"
                               "NOTE: The \e[1m--stream\e[0m option results in the maclog process being never finished,"
                               " due to the necessity of redirecting all logs to Console in real-time.\n"
                               );
                        exit(EXIT_FAILURE);
                    }
                    gLogArgs[gLogTime] = gCurTime();
                }
            }
        }
        else
        {
            prepareLogArgv(showLogArgv);
            gLogArgs[gLogTime] = gCurTime();
        }
        //
        // log the log file
        //
        if (fd >= 0)
        {
            if (dup2(fd, STDOUT_FILENO) < 0) {
                printf("Failed to retrieve logs.\n");
                exit(EXIT_FAILURE);
            }
        }

        //
        // log system log now
        //
        execvp(gLogArgs[0], gLogArgs);
    }
    else if (rc == 0)
    {
        //
        // child process
        //
        wait(NULL);
        if(access(gLogPath, F_OK) == 0) execvp(gOpenf[0], gOpenf);
    }
    else
    {
        //
        // fork failed
        //
        printf("Fork failed\n");
        return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}
