//
// maclog.h
// maclog
//
//  Created by lighting on 1/7/17.
//  Copyright (c) 2017 syscl. All rights reserved.
//
// This work is licensed under the Creative Commons Attribution-NonCommercial
// 4.0 Unported License => http://creativecommons.org/licenses/by-nc/4.0
//
#define PROGRAM_VER 1.4

#include <Carbon/Carbon.h>

//
// for open(...)
//
#include <fcntl.h>
#include <sys/stat.h>
//
// for sysctl(...)
//
#include <sys/sysctl.h>
//
// for time
//
#include <time.h>
#include <string.h>
//
// for access to old ASL logging system
//
#include <asl.h>

//
// Power Management's ASL keys
// from: https://opensource.apple.com/source/PowerManagement/PowerManagement-637.50.9/common/CommonLib.h.auto.html
// TODO: Find a way to include PowerManagement CommonLib.h, so we don't have to define this here.
//
#define kPMASLDomainKey "com.apple.iokit.domain"
#define kPMASLStorePath "/var/log/powermanagement"
#define kPMASLDomainPMWake "Wake"
#define kPMASLDomainPMSleep "Sleep"
#define kPMASLDomainPMDarkWake "DarkWake"

//
// file permission, we use 0644 for both convince and safety reason
//
#define PERMS 0644

//
// get default log name and path
//
char *gLogPath = "/tmp/system.log";

//
// get log argv
//
//char* gLogArgs[] = { "log", "show", "--predicate", "processID == 0", "--debug", 0 };
char *gLogArgs[] = {
        "log",
        "show",
        "--predicate",
        "process == \"kernel\" OR eventMessage CONTAINS \"kernel\"",
        "--style",
        "syslog",
        "--source",
        "--info",
        "--start",
        NULL,
        NULL
};

//
// Get open argv
//
char *gOpenf[3] = {
        "open",
        NULL,
        NULL
};
