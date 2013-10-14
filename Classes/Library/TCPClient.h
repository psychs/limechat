// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Cocoa/Cocoa.h>
#import "AsyncSocket.h"


@interface TCPClient : NSObject

@property (nonatomic, weak) id delegate;
@property (nonatomic) NSString* host;
@property (nonatomic) int port;
@property (nonatomic) BOOL useSSL;

@property (nonatomic) BOOL useSystemSocks;
@property (nonatomic) BOOL useSocks;
@property (nonatomic) int socksVersion;
@property (nonatomic) NSString* proxyHost;
@property (nonatomic) int proxyPort;
@property (nonatomic) NSString* proxyUser;
@property (nonatomic) NSString* proxyPassword;
@property (nonatomic, readonly) int sendQueueSize;

@property (nonatomic, readonly) BOOL active;
@property (nonatomic, readonly) BOOL connecting;
@property (nonatomic, readonly) BOOL connected;

- (id)initWithExistingConnection:(AsyncSocket*)socket;

- (void)open;
- (void)close;

- (NSData*)read;
- (NSData*)readLine;
- (void)write:(NSData*)data;

@end


@interface NSObject (TCPClientDelegate)
- (void)tcpClientDidConnect:(TCPClient*)sender;
- (void)tcpClientDidDisconnect:(TCPClient*)sender;
- (void)tcpClient:(TCPClient*)sender error:(NSString*)error;
- (void)tcpClientDidReceiveData:(TCPClient*)sender;
- (void)tcpClientDidSendData:(TCPClient*)sender;
@end
