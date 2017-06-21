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
    if(sysctl(mib, 2, &gBootTime, &len, NULL, 0) < 0) return gCurTime();

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

        gLogArgs[9] = argc > 1 && (strcmp(argv[1], "--boot") == 0)
            ? gBootTime()
            : gCurTime();

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
        gOpenf[0] = "open";
        gOpenf[1] = gLogPath;
        gOpenf[2] = NULL;
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
