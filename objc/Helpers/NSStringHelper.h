#import <Foundation/Foundation.h>


@interface NSString (NSStringHelper)

- (BOOL)isEmpty;
- (BOOL)contains:(NSString*)str;
- (BOOL)containsIgnoringCase:(NSString*)str;
- (int)findCharacter:(UniChar)c;
- (int)findCharacter:(UniChar)c start:(int)start;
- (int)findString:(NSString*)str;
- (NSArray*)split:(NSString*)delimiter;
- (NSString*)trim;

- (int)firstCharCodePoint;
- (int)lastCharCodePoint;

- (NSString*)stripEffects;

- (NSRange)rangeOfUrl;
- (NSRange)rangeOfUrlStart:(int)start;

- (BOOL)isChannelName;
- (BOOL)isModeChannelName;

+ (NSString*)bundleString:(NSString*)key;

@end

@interface NSMutableString (NSMutableStringHelper)

- (NSString*)getToken;

@end
