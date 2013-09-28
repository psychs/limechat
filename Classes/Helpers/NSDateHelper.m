// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "NSDateHelper.h"
#include <time.h>
#include <xlocale.h>

#define ISO8601_MAX_LEN 25

@implementation NSDate (NSDateHelper)

// Adapted from https://github.com/soffes/sstoolkit

+ (NSDate *)dateFromISO8601String:(NSString *)iso8601
{
    time_t timeInterval = [self timeIntervalFromISO8601String:iso8601];
    if (timeInterval) {
        return [NSDate dateWithTimeIntervalSince1970:timeInterval];
    } else {
        return nil;
    }
}

+ (time_t)timeIntervalFromISO8601String:(NSString *)iso8601
{
    if (!iso8601) {
        return 0;
    }

    const char *str = [iso8601 cStringUsingEncoding:NSUTF8StringEncoding];
    char newStr[ISO8601_MAX_LEN];
    bzero(newStr, ISO8601_MAX_LEN);
    int oldPos = 0;
    int newPos = 0;

    size_t len = strlen(str);
    if (len == 0) {
        return 0;
    }

    // Copy date/time
    if (len >= oldPos + 19) {
        memcpy(newStr + newPos, str + oldPos, 19);
        oldPos += 19;
        newPos += 19;
    }

    // Skip milliseconds if included
    if (len >= oldPos + 4 && str[oldPos] == '.') {
        oldPos += 4;
    }

    // UTC dates ending with Z
    if (len >= oldPos + 1 && str[oldPos] == 'Z') {
        strncpy(newStr + newPos, "+0000", 5);
        oldPos += 1;
        newPos += 5;
    }

    // Timezone includes a semicolon (not supported by strptime)
    else if (len >= oldPos + 5 && str[oldPos + 3] == ':') {
        memcpy(newStr + newPos, str + oldPos, 3);
        memcpy(newStr + newPos + 3, str + oldPos + 4, 2);
        oldPos += 6;
        newPos += 5;
    }

    // Timezone was already well-formatted OR any other case (bad-formatted)
    else if (len >= oldPos + 5) {
        memcpy(newStr + newPos, str + oldPos, 5);
        oldPos += 5;
        newPos += 5;
    }

    // Add null terminator
    newStr[newPos] = 0;

    struct tm tm = {
        .tm_sec = 0,
        .tm_min = 0,
        .tm_hour = 0,
        .tm_mday = 0,
        .tm_mon = 0,
        .tm_year = 0,
        .tm_wday = 0,
        .tm_yday = 0,
        .tm_isdst = -1,
    };

    if (strptime_l(newStr, "%FT%T%z", &tm, NULL) == NULL) {
        return 0;
    }

    return mktime(&tm);
}

@end
