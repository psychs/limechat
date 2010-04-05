// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import <Cocoa/Cocoa.h>


@interface NewPreferences : NSObject

+ (NSDictionary*)loadWorld;

+ (BOOL)boolForKey:(NSString*)key;
+ (NSString*)stringForKey:(NSString*)key;
+ (NSDictionary*)dictionaryForKey:(NSString*)key;

@end
