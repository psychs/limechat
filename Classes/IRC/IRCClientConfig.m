// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "IRCClientConfig.h"
#import "IRCChannelConfig.h"
#import "IgnoreItem.h"
#import "NSDictionaryHelper.h"
#import "NSLocaleHelper.h"


@implementation IRCClientConfig
{
    NSString* name;

    // connection
    NSString* host;
    int port;
    BOOL useSSL;

    // user
    NSString* nick;
    NSString* password;
    NSString* username;
    NSString* realName;
    NSString* nickPassword;
    BOOL useSASL;
    NSMutableArray* altNicks;

    // proxy
    ProxyType proxyType;
    NSString* proxyHost;
    int proxyPort;
    NSString* proxyUser;
    NSString* proxyPassword;

    // others
    BOOL autoConnect;
    NSStringEncoding encoding;
    NSStringEncoding fallbackEncoding;
    NSString* leavingComment;
    NSString* userInfo;
    BOOL invisibleMode;
    NSMutableArray* loginCommands;
    NSMutableArray* channels;
    NSMutableArray* autoOp;
    NSMutableArray* ignores;

    // internal
    int uid;
}

@synthesize name;

@synthesize host;
@synthesize port;
@synthesize useSSL;

@synthesize nick;
@synthesize password;
@synthesize username;
@synthesize realName;
@synthesize nickPassword;
@synthesize useSASL;
@synthesize altNicks;

@synthesize proxyType;
@synthesize proxyHost;
@synthesize proxyPort;
@synthesize proxyUser;
@synthesize proxyPassword;

@synthesize autoConnect;
@synthesize encoding;
@synthesize fallbackEncoding;
@synthesize leavingComment;
@synthesize userInfo;
@synthesize invisibleMode;
@synthesize loginCommands;
@synthesize channels;
@synthesize autoOp;
@synthesize ignores;

@synthesize uid;

- (id)init
{
    self = [super init];
    if (self) {
        altNicks = [NSMutableArray new];
        loginCommands = [NSMutableArray new];
        channels = [NSMutableArray new];
        autoOp = [NSMutableArray new];
        ignores = [NSMutableArray new];
        
        name = @"";
        host = @"";
        port = 6667;
        password = @"";
        nick = @"";
        username = @"";
        realName = @"";
        nickPassword = @"";
        
        proxyHost = @"";
        proxyPort = 1080;
        proxyUser = @"";
        proxyPassword = @"";
        
        encoding = NSUTF8StringEncoding;
        fallbackEncoding = NSISOLatin1StringEncoding;
        leavingComment = @"Leaving...";
        userInfo = @"";
        
        if ([NSLocale prefersJapaneseLanguage]) {
            encoding = NSISO2022JPStringEncoding;
        }
    }
    return self;
}

- (id)initWithDictionary:(NSDictionary*)dic
{
    self = [self init];
    if (self) {
        name = [[dic stringForKey:@"name"] retain] ?: @"";

        host = [[dic stringForKey:@"host"] retain] ?: @"";
        port = [dic intForKey:@"port"] ?: 6667;
        password = [[dic stringForKey:@"password"] retain] ?: @"";
        useSSL = [dic boolForKey:@"ssl"];

        nick = [[dic stringForKey:@"nick"] retain] ?: @"";
        username = [[dic stringForKey:@"username"] retain] ?: @"";
        realName = [[dic stringForKey:@"realname"] retain] ?: @"";
        nickPassword = [[dic stringForKey:@"nickPassword"] retain] ?: @"";
        useSASL = [dic boolForKey:@"useSASL"];
        [altNicks addObjectsFromArray:[dic arrayForKey:@"alt_nicks"]];

        proxyType = [dic intForKey:@"proxy"];
        proxyHost = [[dic stringForKey:@"proxy_host"] retain] ?: @"";
        proxyPort = [dic intForKey:@"proxy_port"] ?: 1080;
        proxyUser = [[dic stringForKey:@"proxy_user"] retain] ?: @"";
        proxyPassword = [[dic stringForKey:@"proxy_password"] retain] ?: @"";

        autoConnect = [dic boolForKey:@"auto_connect"];
        encoding = [dic intForKey:@"encoding"] ?: NSUTF8StringEncoding;
        fallbackEncoding = [dic intForKey:@"fallback_encoding"] ?: NSISOLatin1StringEncoding;
        leavingComment = [[dic stringForKey:@"leaving_comment"] retain] ?: @"";
        userInfo = [[dic stringForKey:@"userinfo"] retain] ?: @"";
        invisibleMode = [dic boolForKey:@"invisible"];

        [loginCommands addObjectsFromArray:[dic arrayForKey:@"login_commands"]];

        for (NSDictionary* e in [dic arrayForKey:@"channels"]) {
            IRCChannelConfig* c = [[[IRCChannelConfig alloc] initWithDictionary:e] autorelease];
            [channels addObject:c];
        }

        [autoOp addObjectsFromArray:[dic arrayForKey:@"autoop"]];

        for (NSDictionary* e in [dic arrayForKey:@"ignores"]) {
            IgnoreItem* ignore = [[[IgnoreItem alloc] initWithDictionary:e] autorelease];
            [ignores addObject:ignore];
        }
    }
    return self;
}

- (void)dealloc
{
    [name release];
    
    [host release];
    
    [nick release];
    [password release];
    [username release];
    [realName release];
    [nickPassword release];
    [altNicks release];
    
    [proxyHost release];
    [proxyUser release];
    [proxyPassword release];
    
    [leavingComment release];
    [userInfo release];
    [loginCommands release];
    [channels release];
    [autoOp release];
    [ignores release];
    
    [super dealloc];
}

- (NSMutableDictionary*)dictionaryValue
{
    NSMutableDictionary* dic = [NSMutableDictionary dictionary];
    
    if (name) dic[@"name"] = name;
    
    if (host) dic[@"host"] = host;
    [dic setInt:port forKey:@"port"];
    [dic setBool:useSSL forKey:@"ssl"];
    
    if (nick) dic[@"nick"] = nick;
    if (password) dic[@"password"] = password;
    if (username) dic[@"username"] = username;
    if (realName) dic[@"realname"] = realName;
    if (nickPassword) dic[@"nickPassword"] = nickPassword;
    [dic setBool:useSASL forKey:@"useSASL"];
    if (altNicks) dic[@"alt_nicks"] = altNicks;
    
    [dic setInt:proxyType forKey:@"proxy"];
    if (proxyHost) dic[@"proxy_host"] = proxyHost;
    [dic setInt:proxyPort forKey:@"proxy_port"];
    if (proxyUser) dic[@"proxy_user"] = proxyUser;
    if (proxyPassword) dic[@"proxy_password"] = proxyPassword;
    
    [dic setBool:autoConnect forKey:@"auto_connect"];
    [dic setInt:encoding forKey:@"encoding"];
    [dic setInt:fallbackEncoding forKey:@"fallback_encoding"];
    if (leavingComment) dic[@"leaving_comment"] = leavingComment;
    if (userInfo) dic[@"userinfo"] = userInfo;
    [dic setBool:invisibleMode forKey:@"invisible"];
    
    if (loginCommands) dic[@"login_commands"] = loginCommands;
    
    NSMutableArray* channelAry = [NSMutableArray array];
    for (IRCChannelConfig* e in channels) {
        [channelAry addObject:[e dictionaryValue]];
    }
    dic[@"channels"] = channelAry;

    dic[@"autoop"] = autoOp;

    NSMutableArray* ignoreAry = [NSMutableArray array];
    for (IgnoreItem* e in ignores) {
        if (e.isValid) {
            [ignoreAry addObject:[e dictionaryValue]];
        }
    }
    dic[@"ignores"] = ignoreAry;

    return dic;
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
    return [[IRCClientConfig allocWithZone:zone] initWithDictionary:[self dictionaryValue]];
}

@end
