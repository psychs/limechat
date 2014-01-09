// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Security/Security.h>
#import "Keychain.h"


static SecProtocolType SecProtocolTypeFromString(NSString* scheme);


@implementation Keychain

#pragma mark - Internet Keychain

+ (BOOL)testInternetPasswordWithName:(NSString*)name url:(NSURL*)url
{
    OSStatus status;
    [self internetPasswordWithName:name url:url status:&status];
    return status != userCanceledErr && status != errSecAuthFailed;
}

+ (NSString*)internetPasswordWithName:(NSString*)name url:(NSURL*)url
{
    OSStatus status;
    return [self internetPasswordWithName:name url:url status:&status];
}

+ (NSString*)internetPasswordWithName:(NSString*)name url:(NSURL*)url status:(OSStatus*)status
{
    char* str = NULL;
    UInt32 len = 0;
    NSString* result = nil;

    const char* nameStr = [name UTF8String];
    const char* hostStr = [[url host] UTF8String];
    const char* pathStr = [[url path] UTF8String];
    int port = [[url port] intValue];

    *status = SecKeychainFindInternetPassword(NULL, strlen(hostStr), hostStr, 0, NULL, strlen(nameStr), nameStr, strlen(pathStr), pathStr, port,SecProtocolTypeFromString([url scheme]), kSecAuthenticationTypeDefault, &len, (void**)&str, NULL);

    if (*status == noErr) {
        result = [[NSString alloc] initWithBytes:str length:len encoding:NSUTF8StringEncoding];
    }

    if (str) {
        SecKeychainItemFreeContent(NULL, str);
    }

    return result;
}

+ (void)setInternetPassword:(NSString*)password name:(NSString*)name url:(NSURL*)url
{
    [self deleteInternetPasswordWithName:name url:url];
    [self addInternetPassword:password name:name url:url];
}

+ (void)addInternetPassword:(NSString*)password name:(NSString*)name url:(NSURL*)url
{
    const char* passwordStr = [password UTF8String];
    const char* nameStr = [name UTF8String];
    const char* hostStr = [[url host] UTF8String];
    const char* pathStr = [[url path] UTF8String];
    int port = [[url port] intValue];
    
    SecKeychainAddInternetPassword(NULL, strlen(hostStr), hostStr, 0, NULL, strlen(nameStr), nameStr, strlen(pathStr), pathStr, port, SecProtocolTypeFromString([url scheme]), kSecAuthenticationTypeDefault, strlen(passwordStr), passwordStr, NULL);
}

+ (void)deleteInternetPasswordWithName:(NSString*)name url:(NSURL*)url
{
    SecKeychainItemRef item = NULL;
    
    const char* nameStr = [name UTF8String];
    const char* hostStr = [[url host] UTF8String];
    const char* pathStr = [[url path] UTF8String];
    int port = [[url port] intValue];
    
    SecKeychainFindInternetPassword(NULL, strlen(hostStr), hostStr, 0, NULL, strlen(nameStr), nameStr, strlen(pathStr), pathStr, port, SecProtocolTypeFromString([url scheme]), kSecAuthenticationTypeDefault, NULL, NULL, &item);
    
    if (item) {
        SecKeychainItemDelete(item);
        CFRelease(item);
    }
}

#pragma mark - Generic Keychain

+ (BOOL)testGenericPasswordWithAccountName:(NSString*)accountName serviceName:(NSString*)serviceName
{
    OSStatus status;
    [self genericPasswordWithAccountName:accountName serviceName:serviceName status:&status];
    return status != userCanceledErr && status != errSecAuthFailed;
}

+ (NSString*)genericPasswordWithAccountName:(NSString*)accountName serviceName:(NSString*)serviceName
{
    OSStatus status;
    return [self genericPasswordWithAccountName:accountName serviceName:serviceName status:&status];
}

+ (NSString*)genericPasswordWithAccountName:(NSString*)accountName serviceName:(NSString*)serviceName status:(OSStatus*)status
{
    char* str = NULL;
    UInt32 len = 0;
    NSString* result = nil;
    
    const char* serviceNameStr = [serviceName UTF8String];
    const char* accountNameStr = [accountName UTF8String];
    
    *status = SecKeychainFindGenericPassword(NULL, strlen(serviceNameStr), serviceNameStr, strlen(accountNameStr), accountNameStr, &len, (void**)&str, NULL);
    
    if (*status == noErr) {
        result = [[NSString alloc] initWithBytes:str length:len encoding:NSUTF8StringEncoding];
    }
    
    if (str) {
        SecKeychainItemFreeContent(NULL, str);
    }
    
    return result;
}

+ (void)setGenericPassword:(NSString*)password accountName:(NSString*)accountName serviceName:(NSString*)serviceName
{
    [self deleteGenericPasswordWithAccountName:accountName serviceName:serviceName];
    [self addGenericPassword:password accountName:accountName serviceName:serviceName];
}

+ (void)addGenericPassword:(NSString*)password accountName:(NSString*)accountName serviceName:(NSString*)serviceName
{
    const char* serviceNameStr = [serviceName UTF8String];
    const char* accountNameStr = [accountName UTF8String];
    const char* passwordStr = [password UTF8String];
    
    SecKeychainAddGenericPassword(NULL, strlen(serviceNameStr), serviceNameStr, strlen(accountNameStr), accountNameStr, strlen(passwordStr), passwordStr, NULL);
}

+ (void)deleteGenericPasswordWithAccountName:(NSString*)accountName serviceName:(NSString*)serviceName
{
    SecKeychainItemRef item = NULL;
    
    const char* serviceNameStr = [serviceName UTF8String];
    const char* accountNameStr = [accountName UTF8String];
    
    SecKeychainFindGenericPassword(NULL, strlen(serviceNameStr), serviceNameStr, strlen(accountNameStr), accountNameStr, NULL, NULL, &item);
    
    if (item) {
        SecKeychainItemDelete(item);
        CFRelease(item);
    }
}

@end


static SecProtocolType SecProtocolTypeFromString(NSString* scheme)
{
    static NSDictionary* dic = nil;
    if (!dic) {
        dic = @{
            @"ftp": @(kSecProtocolTypeFTP),
            @"http": @(kSecProtocolTypeHTTP),
            @"https": @(kSecProtocolTypeHTTPS),
            @"irc": @(kSecProtocolTypeIRC)
        };
    }
    return (SecProtocolType)[[dic objectForKey:scheme] intValue];
}
