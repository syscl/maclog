//
//  maclog.c
//  maclog
//
//  Created by lighting on 1/7/17.
//  Copyright (c) 2017 syscl. All rights reserved.
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 4.0 International License
//  https://creativecommons.org/licenses/by-nc/4.0/
//
#include <stdio.h>  // printf(...)
#include <fcntl.h>  // for open(...)
#include <spawn.h>  // posix_spawn(...)
#include <unistd.h> // for fork(...), ftruncate(...), close(...), unlink(...), dup2(...), execve(...) and Standard File Descriptors
#include <stdlib.h> // waitpid(...) and EXIT flags
#include <signal.h> // kill(...)
#include <stdbool.h> // bool

#include "maclog.h"
#include "arguments.h"

//
// Cleanup
//
static inline void cleanup (int logFileFd, bool unlinkLogFile) {
    freeArgumentMemory();
    if (logFileFd >= 0) close(logFileFd);
    if (unlinkLogFile) unlink(gLogPath);
}

int main(int argc, char *argv[])
{
    int logFileFd;
    pid_t pid, consoleProcessId;

    //
    // Handle arguments
    //
    switch (parseArguments(argc, argv))
    {
        case 1:
            return EXIT_SUCCESS;
        case -1:
            return EXIT_FAILURE;
    }

    //
    // open log file
    //
    logFileFd = open(gLogPath, O_CREAT | O_WRONLY, PERMS);
    if (logFileFd == -1)
    {
        ERROR("Failed to open Log file\n");
        cleanup(-1, false);
        return EXIT_FAILURE;
    }

    //
    // lock access to log file
    //
    if (flock(logFileFd, LOCK_EX | LOCK_NB) == -1)
    {
        ERROR("Failed to access log file. Maybe another maclog instance is running?\n");
        cleanup(logFileFd, false);
        return EXIT_FAILURE;
    }

    //
    // Truncate log file
    //
    if (ftruncate(logFileFd, 0) == -1) // truncate log file
    {
        ERROR("Failed to access log file.\n");
        cleanup(logFileFd, true);
        return EXIT_FAILURE;
    }

    switch (pid = fork())
    {
        case -1: // Error while forking
            ERROR("Fork failed\n");
            cleanup(logFileFd, true);
            return EXIT_FAILURE;
        case 0: // Child process
            switch (pid = fork())
            {
                case -1: // Error while forking
                    ERROR("Fork failed\n");
                    cleanup(logFileFd, true);
                    return EXIT_FAILURE;
                case 0: // Child process
                    //
                    // Open system log with correct arguments and redirect it's output to /tmp/system.log file
                    //
                    if (close(STDOUT_FILENO) == 0 &&
                        dup2(logFileFd, STDOUT_FILENO) == STDOUT_FILENO) // Redirect STDOUT to log file
                    {
                        execve(logArgs[0], logArgs, environ); // Exec system log
                        // After this point things only get executed if execve fails
                    }

                    ERROR("Failed to start system log\n");
                    cleanup(logFileFd, false);
                    return EXIT_FAILURE;
                default: // Parent process
                    //
                    // Open Console.app with correct arguments and wait till it ends to clean up
                    //
                    if (posix_spawn(&consoleProcessId, openArgs[0], NULL, NULL, openArgs, environ) == 0) // Open Console.app
                    {
                        waitpid(consoleProcessId, NULL, 0); // wait Console.app process
                    }

                    if (waitpid(pid, NULL, WNOHANG) == 0) // Check if our log child process is still running
                    {
                        kill(pid, SIGINT); // kill it
                    }

                    cleanup(logFileFd, true);
                    return EXIT_SUCCESS;
            }
        default: // Parent process
            //
            // Print maclog info
            //
            printf(VERSION_INFO);

            //
            // Close parent process to release shell
            //
            cleanup(logFileFd, false);
            return EXIT_SUCCESS;
    }
}
