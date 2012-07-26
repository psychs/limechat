// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Cocoa/Cocoa.h>


typedef enum {
    PROXY_NONE = 0,
    PROXY_SOCKS_SYSTEM = 1,
    PROXY_SOCKS4 = 4,
    PROXY_SOCKS5 = 5,
} ProxyType;


@interface IRCClientConfig : NSObject <NSMutableCopying>
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

@property (nonatomic, strong) NSString* name;

@property (nonatomic, strong) NSString* host;
@property (nonatomic) int port;
@property (nonatomic) BOOL useSSL;

@property (nonatomic, strong) NSString* nick;
@property (nonatomic, strong) NSString* password;
@property (nonatomic, strong) NSString* username;
@property (nonatomic, strong) NSString* realName;
@property (nonatomic, strong) NSString* nickPassword;
@property (nonatomic) BOOL useSASL;
@property (nonatomic, readonly) NSMutableArray* altNicks;

@property (nonatomic) ProxyType proxyType;
@property (nonatomic, strong) NSString* proxyHost;
@property (nonatomic) int proxyPort;
@property (nonatomic, strong) NSString* proxyUser;
@property (nonatomic, strong) NSString* proxyPassword;

@property (nonatomic) BOOL autoConnect;
@property (nonatomic) NSStringEncoding encoding;
@property (nonatomic) NSStringEncoding fallbackEncoding;
@property (nonatomic, strong) NSString* leavingComment;
@property (nonatomic, strong) NSString* userInfo;
@property (nonatomic) BOOL invisibleMode;
@property (nonatomic, readonly) NSMutableArray* loginCommands;
@property (nonatomic, readonly) NSMutableArray* channels;
@property (nonatomic, readonly) NSMutableArray* autoOp;
@property (nonatomic, readonly) NSMutableArray* ignores;

@property (nonatomic) int uid;

- (id)initWithDictionary:(NSDictionary*)dic;
- (NSMutableDictionary*)dictionaryValue;

@end
