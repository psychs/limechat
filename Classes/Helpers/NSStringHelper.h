// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import <Foundation/Foundation.h>


#define IsNumeric(c)						('0' <= (c) && (c) <= '9')
#define IsAlpha(c)							('a' <= (c) && (c) <= 'z' || 'A' <= (c) && (c) <= 'Z')
#define IsAlphaNum(c)						(IsAlpha(c) || IsNumeric(c))
#define IsWordLetter(c)						(IsAlphaNum(c) || (c) == '_')
#define IsAlphaWithDiacriticalMark(c)		(0xc0 <= c && c <= 0xff && c != 0xd7 && c != 0xf7)


@interface NSString (NSStringHelper)

- (BOOL)isEqualNoCase:(NSString*)other;
- (BOOL)isEmpty;
- (BOOL)contains:(NSString*)str;
- (BOOL)containsIgnoringCase:(NSString*)str;
- (int)findCharacter:(UniChar)c;
- (int)findCharacter:(UniChar)c start:(int)start;
- (int)findString:(NSString*)str;
- (NSArray*)split:(NSString*)delimiter;
- (NSArray*)splitIntoLines;
- (NSString*)trim;

- (BOOL)isNumericOnly;

- (int)firstCharCodePoint;
- (int)lastCharCodePoint;

- (NSString*)safeUsername;
- (NSString*)safeFileName;

- (NSString*)stripEffects;

- (NSRange)rangeOfUrl;
- (NSRange)rangeOfUrlStart:(int)start;

- (NSRange)rangeOfAddress;
- (NSRange)rangeOfAddressStart:(int)start;

- (NSRange)rangeOfChannelName;
- (NSRange)rangeOfChannelNameStart:(int)start;

- (BOOL)isChannelName;
- (BOOL)isModeChannelName;
- (NSString*)canonicalName;

+ (NSString*)bundleString:(NSString*)key;

@end

@interface NSMutableString (NSMutableStringHelper)

- (NSString*)getToken;

@end
