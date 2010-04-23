// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the new BSD license.

#import <Foundation/Foundation.h>


@interface UnicodeHelper : NSObject

+ (BOOL)isPrivate:(UniChar)c;
+ (BOOL)isIdeographic:(UniChar)c;
+ (BOOL)isIdeographicOrPrivate:(UniChar)c;
+ (BOOL)isAlphabeticalCodePoint:(int)c;

@end
