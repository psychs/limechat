// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Cocoa/Cocoa.h>
#import "TCPClient.h"
#import "Timer.h"


@interface IRCConnection : NSObject
{
	id delegate;
	
	NSString* host;
	int port;
	BOOL useSSL;
	NSStringEncoding encoding;
	
	BOOL useSystemSocks;
	BOOL useSocks;
	int socksVersion;
	NSString* proxyHost;
	int proxyPort;
	NSString* proxyUser;
	NSString* proxyPassword;
	
	TCPClient* conn;
	NSMutableArray* sendQueue;
	Timer* timer;
	BOOL sending;
	int penalty;
	BOOL loggedIn;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, retain) NSString* host;
@property (nonatomic, assign) int port;
@property (nonatomic, assign) BOOL useSSL;
@property (nonatomic, assign) NSStringEncoding encoding;

@property (nonatomic, assign) BOOL useSystemSocks;
@property (nonatomic, assign) BOOL useSocks;
@property (nonatomic, assign) int socksVersion;
@property (nonatomic, retain) NSString* proxyHost;
@property (nonatomic, assign) int proxyPort;
@property (nonatomic, retain) NSString* proxyUser;
@property (nonatomic, retain) NSString* proxyPassword;

@property (nonatomic, readonly) BOOL active;
@property (nonatomic, readonly) BOOL connecting;
@property (nonatomic, readonly) BOOL connected;
@property (nonatomic, readonly) BOOL readyToSend;
@property (nonatomic, assign) BOOL loggedIn;

- (void)open;
- (void)close;
- (void)clearSendQueue;
- (void)sendLine:(NSString*)line;

- (NSData*)convertToCommonEncoding:(NSString*)s;

@end


@interface NSObject (IRCConnectionDelegate)
- (void)ircConnectionDidConnect:(IRCConnection*)sender;
- (void)ircConnectionDidDisconnect:(IRCConnection*)sender;
- (void)ircConnectionDidError:(NSString*)error;
- (void)ircConnectionDidReceive:(NSData*)data;
- (void)ircConnectionWillSend:(NSString*)line;
@end


