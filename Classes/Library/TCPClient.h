// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Cocoa/Cocoa.h>
#import "AsyncSocket.h"


@interface TCPClient : NSObject
{
    __weak id delegate;

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

@property (nonatomic, weak) id delegate;
@property (nonatomic, strong) NSString* host;
@property (nonatomic) int port;
@property (nonatomic) BOOL useSSL;

@property (nonatomic) BOOL useSystemSocks;
@property (nonatomic) BOOL useSocks;
@property (nonatomic) int socksVersion;
@property (nonatomic, strong) NSString* proxyHost;
@property (nonatomic) int proxyPort;
@property (nonatomic, strong) NSString* proxyUser;
@property (nonatomic, strong) NSString* proxyPassword;
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
