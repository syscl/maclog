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
#include <asl.h> // for access to old ASL logging system
#include <time.h> // for time(...)
#include <sys/sysctl.h> // for sysctl(...)

#include "helper.h"
#include "maclog.h"
#include "gLogTime.h"

//
// get current time
//
char *gCurTime(void)
{
    time_t gRawTime = time(NULL);
    struct tm *gTimeInf = localtime(&gRawTime);
    return gString(11, "%d-%d-%d", gTimeInf->tm_year + 1900, gTimeInf->tm_mon + 1, gTimeInf->tm_mday);
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
    return gString(20, "%d-%d-%d %d:%d:%d",
            gTimeInf->tm_year + 1900,
            gTimeInf->tm_mon + 1,
            gTimeInf->tm_mday,
            gTimeInf->tm_hour,
            gTimeInf->tm_min,
            gTimeInf->tm_sec
    );
}

//
// Modified from PowerManagement CommonLib.h `asl_object_t open_pm_asl_store()`
// https://opensource.apple.com/source/PowerManagement/PowerManagement-637.50.9/common/CommonLib.h.auto.html
// TODO: Sierra's PowerManager still uses the old ASL logging system, that's why we can do this.
// TODO: However I don't know if this will be the case on newer macOS versions.
// TODO: It would be great if someone with High Sierra (10.13), could test this and check if it still works.
//
static asl_object_t searchPowerManagerASLStore(const char *key, const char *value)
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

    return gString(20, "%d-%d-%d %d:%d:%d",
            gTimeInf->tm_year + 1900,
            gTimeInf->tm_mon + 1,
            gTimeInf->tm_mday,
            gTimeInf->tm_hour,
            gTimeInf->tm_min,
            gTimeInf->tm_sec
    );
}