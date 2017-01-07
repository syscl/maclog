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

#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <unistd.h>

//
// syscl::header files
//
#include "maclog.h"

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
        gOpenf[0] = strdup("open");
        gOpenf[1] = strdup(gLogPath);
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
