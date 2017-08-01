//
//  maclog.h
//  maclog
//
//  Created by lighting on 1/7/17.
//  Copyright (c) 2017 syscl. All rights reserved.
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 4.0 International License
//  https://creativecommons.org/licenses/by-nc/4.0/
//
#include <string.h>
#include <getopt.h> // getopt_long(...)

#include "helper.h"
#include "maclog.h"
#include "gLogTime.h"
#include "arguments.h"

//
// Helper function for filter arguments
//
static inline int filterHelper (size_t size, const char *fmt, const char *filter)
{
    static int flag = 1;

    if (flag)
    {
        flag = 0;
        logArgs[gLogFilter] = gString(size, fmt, filter);
        if (logArgs[gLogFilter] != NULL)
        {
            return 0;
        }
        else
        {
            ERROR("Failed to allocate memory.\n");
        }
    }
    else
    {
        ERROR("Filter argument should only be used once.\n");
    }

    // Cleanup
    free(logArgs[gLogFilter]);
    return -1;
}

//
// Parse all received arguments and construct gLogArgs
//
int parseArguments (int argc, char * argv[]) {
    int mode = 0;
    int currentOption = getopt_long(argc, argv, shortOptions, longOptions, NULL); // get next argument

    //
    // Handle arguments
    //
    while (currentOption != -1)
    {
        switch (currentOption)
        {
            case 'v':
                free(logArgs[gLogFilter]); // Cleanup
                printf(VERSION_INFO);
                return 1;
            case 'h':
                free(logArgs[gLogFilter]); // Cleanup
                printf(HELP_MESSAGE);
                return 1;
            case 'f':
                if (filterHelper(
                        sizeof(predicate filterConcat) + strlen(optarg), predicate filterConcat "%s", optarg
                    ) == -1)
                {
                    return -1;
                }
                break;
            case 'F':
                if (filterHelper(
                        sizeof(predicate filterMessage) + strlen(optarg) + 2, predicate filterMessage "\"%s\"", optarg
                    ) == -1)
                {
                    return -1;
                }
                break;
            default:
                if (mode == 0)
                {
                    mode = currentOption;
                    break;
                }

                // Log error
                ERROR("Different modes can't be mixed.\n");
                /* FALLTHROUGH */
            case '?':
                // Error message is logged by getopt
                free(logArgs[gLogFilter]); // Cleanup
                printf(HELP_MESSAGE);
                return -1;
        }

        currentOption = getopt_long(argc, argv, shortOptions, longOptions, NULL); // get next argument
    }

    //
    // Handle default filter
    //
    if (logArgs[gLogFilter] == NULL) if (filterHelper(sizeof(predicate), predicate, NULL) == -1) return -1;

    //
    // Handle modes
    //
    if (mode == 'S') // Stream mode
    {
        logArgs[gLogCommand] = "stream";
        logArgs[7] = "--level";
        logArgs[8] = "info";
    }
    else // Normal modes
    {
        logArgs[gLogCommand] = "show";
        logArgs[7] = "--info";
        logArgs[8] = "--start";

        switch (mode)
        {
            case 0: // no mode argument received, assume default mode
                logArgs[gLogTime] = gCurTime();
                break;
            case 'b':
                logArgs[gLogTime] = gBootTime();
                break;
            case 'd':
                logArgs[gLogTime] = gPowerManagerDomainTime(kPMASLDomainPMDarkWake);
                break;
            case 's':
                logArgs[gLogTime] = gPowerManagerDomainTime(kPMASLDomainPMSleep);
                break;
            case 'w':
                logArgs[gLogTime] = gPowerManagerDomainTime(kPMASLDomainPMWake);
                break;
                // default case will be handled by the if below
        }

        if (logArgs[gLogTime] == NULL)
        {
            // Cleanup
            free(logArgs[gLogFilter]);
            // Log error
            ERROR("Failed to retrieve log for requested mode: %c, Check `--help` to see if it is supported\n",
                    mode);
            return -1;
        }
    }

    return 0;
}

//
// Free memory allocated by arguments
//
void freeArgumentMemory () {
    free(logArgs[gLogTime]);
    free(logArgs[gLogFilter]);
    logArgs[gLogTime] = NULL;
    logArgs[gLogFilter] = NULL;
}
