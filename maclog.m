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
        printf("Failed to retrieve boot time.");
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
    asl_object_t query = asl_new(ASL_TYPE_LIST);
    asl_object_t response = NULL;

    if (query != NULL)
    {
        asl_object_t cq = asl_new(ASL_TYPE_QUERY);
        if (cq != NULL)
        {
            if (asl_set_query(cq, key, value, ASL_QUERY_OP_EQUAL) == 0)
            {
                asl_append(query, cq);
                asl_object_t pmStore = asl_open_path(kPMASLStorePath, 0);
                if (pmStore != NULL) {
                    response = asl_match(pmStore, query, &endMessageID, 0, 0, 0, ASL_MATCH_DIRECTION_FORWARD);
                }
                asl_release(pmStore);
            }
            asl_release(cq);
        }
        asl_release(query);
    }

    return response;
}

char *gPowerManagerDomainTime(const char *domain)
{
    asl_object_t logMessages = searchPowerManagerASLStore(kPMASLDomainKey, domain);

    // Get last message
    aslmsg next;
    aslmsg last = NULL;
    while (NULL != (next = asl_next(logMessages))) last = next;

    if (last == NULL) {
        printf("Failed to retrieve %s time.", domain);
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

int main(int argc, char **argv)
{
    pid_t rc;
    if ((rc = fork()) > 0)
    {
        //
        // parent process, log the file
        //
        int fd = open(gLogPath, O_CREAT | O_TRUNC | O_RDWR, PERMS);
        if (fd >= 0)
        {
            close(STDOUT_FILENO);
            dup2(fd, STDOUT_FILENO);
        }

        //
        // Handle arguments
        //
        if (argc > 1)
        {
            if (strcmp(argv[1], "--boot") == 0)
            {
                gLogArgs[9] = gBootTime();
            }
            else if (strcmp(argv[1], "--sleep") == 0)
            {
                gLogArgs[9] = gPowerManagerDomainTime(kPMASLDomainPMSleep);
            }
            else if (strcmp(argv[1], "--wake") == 0)
            {
                gLogArgs[9] = gPowerManagerDomainTime(kPMASLDomainPMWake);
            }
            else if (strcmp(argv[1], "--darkWake") == 0)
            {
                gLogArgs[9] = gPowerManagerDomainTime(kPMASLDomainPMDarkWake);
            }
            else
            {
                printf("Invalid argument.");
                return EXIT_FAILURE;
            }
        }
        else
        {
            gLogArgs[9] = gCurTime();
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
        printf("v%.1f (c) 2017 syscl/lighting/Yating Zhou\n", PROGRAM_VER);
        wait(NULL);
        gOpenf[1] = gLogPath;
        execvp(gOpenf[0], gOpenf);
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
