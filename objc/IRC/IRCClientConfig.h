// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

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
	
	// internal
	int uid;
}

@property (nonatomic, retain) NSString* name;

@property (nonatomic, retain) NSString* host;
@property (nonatomic, assign) int port;
@property (nonatomic, assign) BOOL useSSL;

@property (nonatomic, retain) NSString* nick;
@property (nonatomic, retain) NSString* password;
@property (nonatomic, retain) NSString* username;
@property (nonatomic, retain) NSString* realName;
@property (nonatomic, retain) NSString* nickPassword;
@property (nonatomic, readonly) NSMutableArray* altNicks;

@property (nonatomic, assign) ProxyType proxyType;
@property (nonatomic, retain) NSString* proxyHost;
@property (nonatomic, assign) int proxyPort;
@property (nonatomic, retain) NSString* proxyUser;
@property (nonatomic, retain) NSString* proxyPassword;

@property (nonatomic, assign) BOOL autoConnect;
@property (nonatomic, assign) NSStringEncoding encoding;
@property (nonatomic, assign) NSStringEncoding fallbackEncoding;
@property (nonatomic, retain) NSString* leavingComment;
@property (nonatomic, retain) NSString* userInfo;
@property (nonatomic, assign) BOOL invisibleMode;
@property (nonatomic, readonly) NSMutableArray* loginCommands;
@property (nonatomic, readonly) NSMutableArray* channels;
@property (nonatomic, readonly) NSMutableArray* autoOp;

@property (nonatomic, assign) int uid;

- (id)initWithDictionary:(NSDictionary*)dic;
- (NSMutableDictionary*)dictionaryValue;

@end
