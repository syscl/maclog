//
//  global.c
//  maclog
//
//  Created by lighting on 1/7/17.
//  Copyright (c) 2017 syscl. All rights reserved.
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 4.0 International License
//  https://creativecommons.org/licenses/by-nc/4.0/
//
#include <stddef.h>
#include <getopt.h>

#include "maclog.h"

//
// Log argv
//
char * logArgs[] = {
        "/usr/bin/log",
        NULL,
        "--predicate",
        NULL,
        "--style",
        "syslog",
        "--source",
        NULL,
        NULL,
        NULL,
        NULL
};

//
// Open argv
//
char *openArgs[] = {
        "/usr/bin/open",
        "-W",
        "-n",
        "-a",
        "Console.app",
        gLogPath,
        NULL
};

//
// Maclog command line short arguments
//
const char shortOptions[] = "bdf:F:hsSvw";

//
// Maclog command line long arguments
//
const struct option longOptions[] = {
        {"boot",          no_argument,       NULL, 'b'},
        {"darkWake",      no_argument,       NULL, 'd'},
        {"filter",        required_argument, NULL, 'f'},
        {"filterMessage", required_argument, NULL, 'F'},
        {"help",          no_argument,       NULL, 'h'},
        {"sleep",         no_argument,       NULL, 's'},
        {"stream",        no_argument,       NULL, 'S'},
        {"version",       no_argument,       NULL, 'v'},
        {"wake",          no_argument,       NULL, 'w'},
        {0,               0,                 0,     0 },
};