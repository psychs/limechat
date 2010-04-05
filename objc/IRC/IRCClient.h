// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import <Cocoa/Cocoa.h>
#import "IRCTreeItem.h"
#import "IRCClientConfig.h"
#import "IRCChannel.h"
#import "LogController.h"
#import "IRCConnection.h"


@class IRCWorld;


@interface IRCClient : NSObject <IRCTreeItem>
{
	IRCWorld* world;
	LogController* log;
	
	IRCClientConfig* config;
	NSMutableArray* channels;
	int uid;
	
	IRCConnection* conn;
	int connectDelay;
	BOOL reconnectEnabled;
	int reconnectTime;
	BOOL retryEnabled;
	int retryTime;
	
	BOOL connecting;
	BOOL connected;
	BOOL login;
	BOOL quitting;
	NSStringEncoding encoding;
	
	NSString* inputNick;
	NSString* sentNick;
	NSString* myNick;
	int tryingNick;
	
	NSString* serverHostname;
	NSString* joinMyAddress;
	BOOL inWhois;
	BOOL identifyMsg;
	BOOL identifyCTCP;
}

@property (nonatomic, assign) IRCWorld* world;
@property (nonatomic, retain) LogController* log;

@property (nonatomic, readonly) NSString* name;
@property (nonatomic, readonly) IRCClientConfig* config;
@property (nonatomic, readonly) NSMutableArray* channels;
@property (nonatomic, assign) int uid;

- (void)setup:(IRCClientConfig*)seed;

- (void)autoConnect:(int)delay;
- (void)onTimer;

- (void)connect;
- (void)disconnect;

- (IRCChannel*)findChannel:(NSString*)name;
- (int)indexOfTalkChannel;

@end
