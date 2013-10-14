// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "LCFSystemInfo.h"

static BOOL initialized;
static SInt32 major;
static SInt32 minor;
static SInt32 bugFix;
static BOOL isMarvericksOrLater;

@implementation LCFSystemInfo

+ (void)_initializeVersionInfo
{
    if (initialized) {
        return;
    }

    initialized = YES;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    Gestalt(gestaltSystemVersionMajor, &major);
    Gestalt(gestaltSystemVersionMinor, &minor);
    Gestalt(gestaltSystemVersionBugFix, &bugFix);
#pragma clang diagnostic pop

    isMarvericksOrLater = (major > 10) || (major == 10 && minor >= 9);
}

+ (BOOL)isMarvericksOrLater
{
    [self _initializeVersionInfo];
    return isMarvericksOrLater;
}

@end
