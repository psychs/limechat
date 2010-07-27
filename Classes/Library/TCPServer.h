// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Foundation/Foundation.h>
#import "TCPClient.h"


@interface TCPServer : NSObject
{
	id delegate;
	
	AsyncSocket* conn;
	NSMutableArray* clients;
	BOOL isActive;
	int port;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, readonly) NSArray* clients;
@property (nonatomic, readonly) BOOL isActive;
@property (nonatomic, assign) int port;

- (BOOL)open;
- (void)close;

- (void)closeClient:(TCPClient*)client;
- (void)closeAllClients;

@end


@interface NSObject (TCPServerDelegate)
- (void)tcpServer:(TCPServer*)sender didAccept:(TCPClient*)client;
- (void)tcpServer:(TCPServer*)sender didConnect:(TCPClient*)client;
- (void)tcpServer:(TCPServer*)sender client:(TCPClient*)client error:(NSString*)error;
- (void)tcpServer:(TCPServer*)sender didDisconnect:(TCPClient*)client;
- (void)tcpServer:(TCPServer*)sender didReceiveData:(TCPClient*)client;
- (void)tcpServer:(TCPServer*)sender didSendData:(TCPClient*)client;
@end
