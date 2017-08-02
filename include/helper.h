//
//  helper.h
//  maclog
//
//  Created by lighting on 1/7/17.
//  Copyright (c) 2017 syscl. All rights reserved.
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 4.0 International License
//  https://creativecommons.org/licenses/by-nc/4.0/
//
#ifndef HELPER_H
#define HELPER_H

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>

//
// Generate string
//
static inline char *gString(size_t size, const char *fmt, ...) {
    char *str = (char *) calloc(size, sizeof(char));
    if (str == NULL) return NULL;

    va_list args;
    va_start(args, fmt);
    int printedChars = vsnprintf(str, size, fmt, args);
    if (printedChars <= 0 || printedChars >= size) {
        free(str);
        str = NULL;
    }
    va_end(args);

    return str;
}

#endif /* HELPER_H */