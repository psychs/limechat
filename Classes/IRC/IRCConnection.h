// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Cocoa/Cocoa.h>
#import "TCPClient.h"
#import "Timer.h"


@interface IRCConnection : NSObject
{
    __weak id delegate;
    
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

@property (nonatomic, weak) id delegate;
@property (nonatomic, strong) NSString* host;
@property (nonatomic) int port;
@property (nonatomic) BOOL useSSL;
@property (nonatomic) NSStringEncoding encoding;

@property (nonatomic) BOOL useSystemSocks;
@property (nonatomic) BOOL useSocks;
@property (nonatomic) int socksVersion;
@property (nonatomic, strong) NSString* proxyHost;
@property (nonatomic) int proxyPort;
@property (nonatomic, strong) NSString* proxyUser;
@property (nonatomic, strong) NSString* proxyPassword;

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


