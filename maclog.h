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
#define PROGRAM_VER 1.6

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
// for time(...)
//
#include <time.h>
#include <string.h>
//
// for access to old ASL logging system
//
#include <asl.h>
//
// for getopt_long(...)
// more info: http://man7.org/linux/man-pages/man3/getopt.3.html
//
#include <getopt.h>
//
// for posix_spawn(...)
//
#include <spawn.h>
//
// for proc_pidpath(...)
//
#include <libproc.h>

extern char **environ;
typedef char ppath_t[PROC_PIDPATHINFO_MAXSIZE];

//
// Power Management's ASL keys
// from: https://opensource.apple.com/source/PowerManagement/PowerManagement-637.50.9/common/CommonLib.h.auto.html
// TODO: Find a way to include PowerManagement CommonLib.h, so we don't have to define this here.
//
#define kPMASLDomainKey           "com.apple.iokit.domain"
#define kPMASLStorePath           "/var/log/powermanagement"
#define kPMASLDomainPMWake        "Wake"
#define kPMASLDomainPMSleep       "Sleep"
#define kPMASLDomainPMDarkWake    "DarkWake"

//
// file permission, we use 0644 for both convince and safety reason
//
#define PERMS 0644

//
// get default log name and path
//
#define gLogPath "/tmp/system.log"

//
// argument flags
//
#define shortOptions "bdf:hsSvw"
struct option longOptions[] = {
    {"boot",        no_argument,        NULL,   'b'},
    {"darkWake",    no_argument,        NULL,   'd'},
    {"filter",      required_argument,  NULL,   'f'},
    {"help",        no_argument,        NULL,   'h'},
    {"sleep",       no_argument,        NULL,   's'},
    {"stream",      no_argument,        NULL,   'S'},
    {"version",     no_argument,        NULL,   'v'},
    {"wake",        no_argument,        NULL,   'w'},
    {0,             0,                  0,       0 },
};

//
// constants for gLogArgs, for making them easy to change and increase readability
//
#define gLogCommand 1
#define gLogTime    9
#define gLogFilter  3

//
// filter
//
#define predicate "(process == \"kernel\" OR eventMessage CONTAINS[c] \"kernel\")"
#define filterConcat " AND "

//
// get log argv
//
char *gLogArgs[] = {
        "/usr/bin/log",
        NULL,
        "--predicate",
        predicate,
        "--style",
        "syslog",
        "--source",
        NULL,
        NULL,
        NULL,
        NULL
};

//
// get open argv
//
char *gOpenf[] = {
        "/usr/bin/open",
        "-W",
        "-a",
        "Console.app",
        gLogPath,
        NULL
};
