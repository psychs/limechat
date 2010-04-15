// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

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
