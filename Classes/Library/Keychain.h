// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Foundation/Foundation.h>


@interface Keychain : NSObject

#pragma mark - Internet Keychain

+ (BOOL)testInternetPasswordWithName:(NSString*)name url:(NSURL*)url;
+ (NSString*)internetPasswordWithName:(NSString*)name url:(NSURL*)url;
+ (void)setInternetPassword:(NSString*)password name:(NSString*)name url:(NSURL*)url;
+ (void)addInternetPassword:(NSString*)password name:(NSString*)name url:(NSURL*)url;
+ (void)deleteInternetPasswordWithName:(NSString*)name url:(NSURL*)url;

#pragma mark - Generic Keychain

+ (BOOL)testGenericPasswordWithAccountName:(NSString*)accountName serviceName:(NSString*)serviceName;
+ (NSString*)genericPasswordWithAccountName:(NSString*)accountName serviceName:(NSString*)serviceName;
+ (void)setGenericPassword:(NSString*)password accountName:(NSString*)accountName serviceName:(NSString*)serviceName;
+ (void)addGenericPassword:(NSString*)password accountName:(NSString*)accountName serviceName:(NSString*)serviceName;
+ (void)deleteGenericPasswordWithAccountName:(NSString*)accountName serviceName:(NSString*)serviceName;

@end
