//
//  gLogTime.h
//  maclog
//
//  Created by lighting on 1/7/17.
//  Copyright (c) 2017 syscl. All rights reserved.
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 4.0 International License
//  https://creativecommons.org/licenses/by-nc/4.0/
//
#ifndef G_LOG_TIME_H
#define G_LOG_TIME_H

//
// Exported prototypes
//
char *gCurTime(void);
char *gBootTime(void);
char *gPowerManagerDomainTime(const char *);

#endif /* G_LOG_TIME_H */