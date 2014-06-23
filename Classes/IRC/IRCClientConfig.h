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

@property (nonatomic) NSString* name;

@property (nonatomic) NSString* host;
@property (nonatomic) int port;
@property (nonatomic) BOOL useSSL;

@property (nonatomic) NSString* nick;
@property (nonatomic) NSString* password;
@property (nonatomic) NSString* username;
@property (nonatomic) NSString* realName;
@property (nonatomic) NSString* nickPassword;
@property (nonatomic) BOOL useSASL;
@property (nonatomic, readonly) NSMutableArray* altNicks;

@property (nonatomic) ProxyType proxyType;
@property (nonatomic) NSString* proxyHost;
@property (nonatomic) int proxyPort;
@property (nonatomic) NSString* proxyUser;
@property (nonatomic) NSString* proxyPassword;

@property (nonatomic) BOOL autoConnect;
@property (nonatomic) NSStringEncoding encoding;
@property (nonatomic) NSStringEncoding fallbackEncoding;
@property (nonatomic) NSString* leavingComment;
@property (nonatomic) NSString* userInfo;
@property (nonatomic) BOOL invisibleMode;
@property (nonatomic, readonly) NSMutableArray* loginCommands;
@property (nonatomic, readonly) NSMutableArray* channels;
@property (nonatomic, readonly) NSMutableArray* autoOp;
@property (nonatomic, readonly) NSMutableArray* ignores;

@property (nonatomic) int uid;

- (id)initWithDictionary:(NSDictionary*)dic;
- (NSMutableDictionary*)dictionaryValueSavingToKeychain:(BOOL)saveToKeychain includingChildren:(BOOL)includingChildren;

- (void)deletePasswordsFromKeychain;

@end
