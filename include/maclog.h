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
#ifndef MACLOG_H
#define MACLOG_H

#include <getopt.h> // struct option

//
// Preprocessor magic
// see: http://www.decompile.com/cpp/faq/file_and_line_error_string.htm
//
#define STRINGIFY(x) #x
#define TO_STRING(x) STRINGIFY(x)

//
// Log error macro
//
#define ERROR(fmt, ...) do { fprintf(stderr, "ERROR: " fmt, ##__VA_ARGS__); } while (0)

//
// Maclog version and info
//
#define PROGRAM_VERSION 1.7
#define VERSION_INFO "v" TO_STRING(PROGRAM_VERSION) " (c) 2017 syscl/lighting/Yating Zhou\n"
#define HELP_MESSAGE                                                                \
    "USAGE: maclog [--version|-v] [--help|-h]\n"                                    \
    "USAGE: maclog [logMode] [-f|--filter=<query>]\n"                               \
    "Arguments:\n"                                                                  \
    " --help    -h Show maclog help info.\n"                                        \
    " --version -v Show maclog version info.\n"                                     \
    "Log Modes:\n"                                                                  \
    " --boot     -b Show log messages since last boot time.\n"                      \
    " --darkWake -d Show log messages since last darkWake time.\n"                  \
    " --sleep    -s Show log messages since last sleep time.\n"                     \
    " --stream   -S Show log messages in real time.\n"                              \
    " --wake     -w Show log messages since last wake time.\n"                      \
    "Filter:\n"                                                                     \
    " --filter        -f Show log messages filtered by the <query>.\n"              \
    " --filterMessage -F Shorthand for -f \"eventMessage CONTAINS[c] <query>\"\n"   \
    "NOTE: The default behaviour is to show all log messages of the current day.\n" \
    "NOTE: The messages returned by \e[1m--boot\e[0m, \e[1m--sleep\e[0m, "          \
    "\e[1m--wake\e[0m, \e[1m--darkWake\e[0m can be from previous days,"             \
    " depending on the last time each action occurred.\n"                           \

//
// file permission, we use 0644 for both convince and safety reason
//
#define PERMS 0644

//
// get default log name and path
//
#define gLogPath "/tmp/system.log"

//
// constants for gLogArgs, for making them easy to change and increase readability
//
#define gLogTime    9
#define gLogFilter  3
#define gLogCommand 1

//
// Power Management's ASL keys
// from: https://opensource.apple.com/source/PowerManagement/PowerManagement-637.50.9/common/CommonLib.h.auto.html
// TODO: Find a way to include PowerManagement CommonLib.h, so we don't have to define this here.
//
#define kPMASLDomainKey        "com.apple.iokit.domain"
#define kPMASLStorePath        "/var/log/powermanagement"
#define kPMASLDomainPMWake     "Wake"
#define kPMASLDomainPMSleep    "Sleep"
#define kPMASLDomainPMDarkWake "DarkWake"

//
// filter predicates
//
#define predicate     "(process == \"kernel\" OR eventMessage CONTAINS[c] \"kernel\")"
#define filterConcat  " AND "
#define filterMessage " AND eventMessage CONTAINS[c] "

//
// Externals
// see `global.c` for definitions
//
extern char** environ; // User environment
extern char* logArgs[]; // Log argv
extern char* openArgs[]; // Open argv
extern const char shortOptions[]; // Maclog command line short arguments
extern const struct option longOptions[]; // Maclog command line long arguments

#endif /* MACLOG_H */
