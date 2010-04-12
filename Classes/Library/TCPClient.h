// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import <Cocoa/Cocoa.h>
#import "AsyncSocket.h"


@interface TCPClient : NSObject
{
	id delegate;
	
	NSString* host;
	int port;
	BOOL useSSL;
	
	BOOL useSystemSocks;
	BOOL useSocks;
	int socksVersion;
	NSString* proxyHost;
	int proxyPort;
	NSString* proxyUser;
	NSString* proxyPassword;
	
	int sendQueueSize;
	
	AsyncSocket* conn;
	NSMutableData* buffer;
	int tag;
	BOOL active;
	BOOL connecting;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, retain) NSString* host;
@property (nonatomic, assign) int port;
@property (nonatomic, assign) BOOL useSSL;

@property (nonatomic, assign) BOOL useSystemSocks;
@property (nonatomic, assign) BOOL useSocks;
@property (nonatomic, assign) int socksVersion;
@property (nonatomic, retain) NSString* proxyHost;
@property (nonatomic, assign) int proxyPort;
@property (nonatomic, retain) NSString* proxyUser;
@property (nonatomic, retain) NSString* proxyPassword;
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
