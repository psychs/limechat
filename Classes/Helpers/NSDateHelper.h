// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Foundation/Foundation.h>

@interface NSDate (NSDateHelper)

/**
 Returns a new date represented by an ISO8601 string.

 Copied from https://github.com/soffes/sstoolkit

 @param iso8601String An ISO8601 string

 @return Date represented by the ISO8601 string
 */

+ (NSDate *)dateFromISO8601String:(NSString *)iso8601String;
+ (time_t)timeIntervalFromISO8601String:(NSString *)iso8601String;

@end
