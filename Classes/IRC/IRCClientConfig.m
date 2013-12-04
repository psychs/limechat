// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "IRCClientConfig.h"
#import "IRCChannelConfig.h"
#import "IgnoreItem.h"
#import "NSDictionaryHelper.h"
#import "NSLocaleHelper.h"


@interface IRCClientConfig (Private)
+ (NSString*) findPassword:(NSString*)user host:(NSString*)host port:(NSUInteger*)port protocol:(SecProtocolType)protocol path:(NSString*)path;
+ (void) setPassword:(NSString*)user password:(NSString*)password host:(NSString*)host port:(NSUInteger*)port protocol:(SecProtocolType)protocol path:(NSString*)path;
@end

@implementation IRCClientConfig

- (id)init
{
    self = [super init];
    if (self) {
        _altNicks = [NSMutableArray new];
        _loginCommands = [NSMutableArray new];
        _channels = [NSMutableArray new];
        _autoOp = [NSMutableArray new];
        _ignores = [NSMutableArray new];

        _name = @"";
        _host = @"";
        _port = 6667;
        _password = @"";
        _nick = @"";
        _username = @"";
        _realName = @"";
        _nickPassword = @"";

        _proxyHost = @"";
        _proxyPort = 1080;
        _proxyUser = @"";
        _proxyPassword = @"";

        _encoding = NSUTF8StringEncoding;
        _fallbackEncoding = NSISOLatin1StringEncoding;
        _leavingComment = @"Leaving...";
        _userInfo = @"";

        if ([NSLocale prefersJapaneseLanguage]) {
            _encoding = NSISO2022JPStringEncoding;
        }
    }
    return self;
}

- (id)initWithDictionary:(NSDictionary*)dic
{
    self = [self init];
    if (self) {
        _name = [dic stringForKey:@"name"] ?: @"";

        _host = [dic stringForKey:@"host"] ?: @"";
        _port = [dic intForKey:@"port"] ?: 6667;
        
        _password = [dic stringForKey:@"password"] ?: @"";
        _useSSL = [dic boolForKey:@"ssl"];

        _nick = [dic stringForKey:@"nick"] ?: @"";
        _username = [dic stringForKey:@"username"] ?: @"";
        _realName = [dic stringForKey:@"realname"] ?: @"";
        _nickPassword = [dic stringForKey:@"nickPassword"] ?: @"";
        _useSASL = [dic boolForKey:@"useSASL"];
        [_altNicks addObjectsFromArray:[dic arrayForKey:@"alt_nicks"]];

        _proxyType = [dic intForKey:@"proxy"];
        _proxyHost = [dic stringForKey:@"proxy_host"] ?: @"";
        _proxyPort = [dic intForKey:@"proxy_port"] ?: 1080;
        _proxyUser = [dic stringForKey:@"proxy_user"] ?: @"";
        _proxyPassword = [dic stringForKey:@"proxy_password"] ?: @"";

        _autoConnect = [dic boolForKey:@"auto_connect"];
        _encoding = [dic intForKey:@"encoding"] ?: NSUTF8StringEncoding;
        _fallbackEncoding = [dic intForKey:@"fallback_encoding"] ?: NSISOLatin1StringEncoding;
        _leavingComment = [dic stringForKey:@"leaving_comment"] ?: @"";
        _userInfo = [dic stringForKey:@"userinfo"] ?: @"";
        _invisibleMode = [dic boolForKey:@"invisible"];

        [_loginCommands addObjectsFromArray:[dic arrayForKey:@"login_commands"]];

        for (NSDictionary* e in [dic arrayForKey:@"channels"]) {
            IRCChannelConfig* c = [[IRCChannelConfig alloc] initWithDictionary:e];
            [_channels addObject:c];
        }

        [_autoOp addObjectsFromArray:[dic arrayForKey:@"autoop"]];

        for (NSDictionary* e in [dic arrayForKey:@"ignores"]) {
            IgnoreItem* ignore = [[IgnoreItem alloc] initWithDictionary:e];
            [_ignores addObject:ignore];
        }

        SecProtocolType protocol = _useSSL ? kSecProtocolTypeIRCS : kSecProtocolTypeIRC;
        if (!_password.length && _username.length)
            _password = [IRCClientConfig findPassword:_username host:_host port:_port protocol:protocol path:NULL];
        if (!_nickPassword.length && _nick.length)
            _nickPassword = [IRCClientConfig findPassword:_nick host:_host port:_port protocol:protocol path:@"/NickServ"];
        if (!_proxyPassword.length && _proxyUser.length)
            _proxyPassword = [IRCClientConfig findPassword:_proxyUser host:_proxyHost port:_proxyPort protocol:kSecProtocolTypeSOCKS path:NULL];
            }
    return self;
}

- (NSMutableDictionary*)dictionaryValue
{
    NSMutableDictionary* dic = [NSMutableDictionary dictionary];

    if (_name) [dic setObject:_name forKey:@"name"];

    if (_host) [dic setObject:_host forKey:@"host"];
    [dic setInt:_port forKey:@"port"];
    [dic setBool:_useSSL forKey:@"ssl"];

    if (_nick) [dic setObject:_nick forKey:@"nick"];
    if (_username) [dic setObject:_username forKey:@"username"];
    if (_realName) [dic setObject:_realName forKey:@"realname"];
    [dic setBool:_useSASL forKey:@"useSASL"];
    if (_altNicks) [dic setObject:_altNicks forKey:@"alt_nicks"];

    [dic setInt:_proxyType forKey:@"proxy"];
    if (_proxyHost) [dic setObject:_proxyHost forKey:@"proxy_host"];
    [dic setInt:_proxyPort forKey:@"proxy_port"];
    if (_proxyUser) [dic setObject:_proxyUser forKey:@"proxy_user"];

    [dic setBool:_autoConnect forKey:@"auto_connect"];
    [dic setInt:_encoding forKey:@"encoding"];
    [dic setInt:_fallbackEncoding forKey:@"fallback_encoding"];
    if (_leavingComment) [dic setObject:_leavingComment forKey:@"leaving_comment"];
    if (_userInfo) [dic setObject:_userInfo forKey:@"userinfo"];
    [dic setBool:_invisibleMode forKey:@"invisible"];

    if (_altNicks) [dic setObject:_loginCommands forKey:@"login_commands"];

    NSMutableArray* channelAry = [NSMutableArray array];
    for (IRCChannelConfig* e in _channels) {
        [channelAry addObject:[e dictionaryValue]];
    }
    [dic setObject:channelAry forKey:@"channels"];

    [dic setObject:_autoOp forKey:@"autoop"];

    NSMutableArray* ignoreAry = [NSMutableArray array];
    for (IgnoreItem* e in _ignores) {
        if (e.isValid) {
            [ignoreAry addObject:[e dictionaryValue]];
        }
    }
    [dic setObject:ignoreAry forKey:@"ignores"];

    SecProtocolType protocol = _useSSL ? kSecProtocolTypeIRCS : kSecProtocolTypeIRC;
    if (_username.length)
        [IRCClientConfig setPassword:_username password:_password host:_host port:_port protocol:protocol path:NULL];
    if (_nick.length)
        [IRCClientConfig setPassword:_nick password:_nickPassword host:_host port:_port protocol:protocol path:@"/NickServ"];
    if (_proxyUser.length)
        [IRCClientConfig setPassword:_proxyUser password:_proxyPassword host:_proxyHost port:_proxyPort protocol:kSecProtocolTypeSOCKS path:NULL];

    return dic;
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
    return [[IRCClientConfig alloc] initWithDictionary:[self dictionaryValue]];
}

+ (NSString *)findPassword:(NSString *)user host:(NSString *)host port:(NSUInteger *)port protocol:(SecProtocolType)protocol path:(NSString *)path
{
    UInt32 passwordLength;
    void *passwordBytes;
    OSStatus result;
    UInt32 pathLength = 0;
    const char *pathString = NULL;
    if (path)
    {
        pathLength = (UInt32)[path lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
        pathString = [path UTF8String];
    }
    result = SecKeychainFindInternetPassword(NULL,
                                             (UInt32)[host lengthOfBytesUsingEncoding:NSUTF8StringEncoding], [host UTF8String],
                                             0, NULL,
                                             (UInt32)[user lengthOfBytesUsingEncoding:NSUTF8StringEncoding], [user UTF8String],
                                             pathLength, pathString,
                                             (UInt16)port,
                                             protocol, kSecAuthenticationTypeAny,
                                             &passwordLength, &passwordBytes, NULL);
    if (result != noErr)
        return @"";

    NSString *password = [[NSString alloc] initWithBytes:passwordBytes length:passwordLength encoding:NSUTF8StringEncoding];
    SecKeychainItemFreeContent(NULL, passwordBytes);
    if (!password)
        return @"";
    return password;
}

+ (void)setPassword:(NSString*)user password:(NSString*)password host:(NSString*)host port:(NSUInteger*)port protocol:(SecProtocolType)protocol path:(NSString*)path
{
    OSStatus result;
    SecKeychainItemRef item = NULL;
    UInt32 pathLength = 0;
    const char *pathString = NULL;
    if (path)
    {
        pathLength = (UInt32)[path lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
        pathString = [path UTF8String];
    }

    result = SecKeychainFindInternetPassword(NULL,
                                             (UInt32)[host lengthOfBytesUsingEncoding:NSUTF8StringEncoding],
                                             [host UTF8String],
                                             0, NULL,
                                             (UInt32)[user lengthOfBytesUsingEncoding:NSUTF8StringEncoding],
                                             [user UTF8String],
                                             pathLength, pathString,
                                             (UInt16)port,
                                             protocol, kSecAuthenticationTypeAny,
                                             NULL, NULL, &item);
    if (result == noErr) {
        if ([password length] > 0) {
            result = SecKeychainItemModifyAttributesAndData(item, NULL,
                                                            (UInt32)[password lengthOfBytesUsingEncoding:NSUTF8StringEncoding],
                                                            [password UTF8String]);
        } else {
            result = SecKeychainItemDelete(item);
        }
    } else if (result == errSecItemNotFound) {
        if ([password length] > 0) {
            result = SecKeychainAddInternetPassword(NULL,
                                                    (UInt32)[host lengthOfBytesUsingEncoding:NSUTF8StringEncoding],
                                                    [host UTF8String],
                                                    0, NULL,
                                                    (UInt32)[user lengthOfBytesUsingEncoding:NSUTF8StringEncoding],
                                                    [user UTF8String],
                                                    pathLength, pathString,
                                                    (UInt16)port,
                                                    protocol, kSecAuthenticationTypeDefault,
                                                    (UInt32)[password lengthOfBytesUsingEncoding:NSUTF8StringEncoding],
                                                    [password UTF8String], NULL);
        }
    }
}

@end
