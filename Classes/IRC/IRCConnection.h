// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Cocoa/Cocoa.h>
#import "TCPClient.h"
#import "Timer.h"


@interface IRCConnection : NSObject

@property (nonatomic, weak) id delegate;
@property (nonatomic) NSString* host;
@property (nonatomic) int port;
@property (nonatomic) BOOL useSSL;
@property (nonatomic) NSStringEncoding encoding;

@property (nonatomic) BOOL useSystemSocks;
@property (nonatomic) BOOL useSocks;
@property (nonatomic) int socksVersion;
@property (nonatomic) NSString* proxyHost;
@property (nonatomic) int proxyPort;
@property (nonatomic) NSString* proxyUser;
@property (nonatomic) NSString* proxyPassword;

@property (nonatomic, readonly) BOOL active;
@property (nonatomic, readonly) BOOL connecting;
@property (nonatomic, readonly) BOOL connected;
@property (nonatomic, readonly) BOOL readyToSend;
@property (nonatomic) BOOL loggedIn;

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


