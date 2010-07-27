// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Foundation/Foundation.h>

@interface NSDictionary (NSDictionaryHelper)

- (BOOL)boolForKey:(NSString*)key;
- (int)intForKey:(NSString*)key;
- (long long)longLongForKey:(NSString*)key;
- (double)doubleForKey:(NSString*)key;
- (NSString*)stringForKey:(NSString*)key;
- (NSDictionary*)dictionaryForKey:(NSString*)key;
- (NSArray*)arrayForKey:(NSString*)key;

@end


@interface NSMutableDictionary (NSMutableDictionaryHelper)

- (void)setBool:(BOOL)value forKey:(NSString*)key;
- (void)setInt:(int)value forKey:(NSString*)key;
- (void)setLongLong:(long long)value forKey:(NSString*)key;
- (void)setDouble:(double)value forKey:(NSString*)key;

@end
