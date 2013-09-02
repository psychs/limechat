// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Foundation/Foundation.h>

#define UnicodeIsRTLCharacter(c) ({ __typeof__(c) __c = (c); (0x0590 <= (__c) && (__c) <= 0x08FF || 0xFB1D <= (__c) && (__c) <= 0xFDFD || 0xFE70 <= (__c) && (__c) <= 0xFEFC); })

@interface UnicodeHelper : NSObject

+ (BOOL)isAlphabeticalCodePoint:(int)c;

@end
