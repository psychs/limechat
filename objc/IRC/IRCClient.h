// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import <Cocoa/Cocoa.h>
#import "IRCTreeItem.h"
#import "IRCClientConfig.h"
#import "IRCChannel.h"
#import "LogController.h"
#import "IRCConnection.h"
#import "IRCISupportInfo.h"
#import "IRCUserMode.h"


@class IRCWorld;


@interface IRCClient : IRCTreeItem
{
	IRCWorld* world;
	
	IRCClientConfig* config;
	NSMutableArray* channels;
	IRCISupportInfo* isupport;
	IRCUserMode* myMode;
	
	IRCConnection* conn;
	int connectDelay;
	BOOL reconnectEnabled;
	int reconnectTime;
	BOOL retryEnabled;
	int retryTime;
	
	BOOL connecting;
	BOOL connected;
	BOOL reconnecting;
	BOOL loggedIn;
	BOOL quitting;
	NSStringEncoding encoding;
	
	NSString* inputNick;
	NSString* sentNick;
	NSString* myNick;
	int tryingNick;
	
	NSString* serverHostname;
	NSString* joinMyAddress;
	NSString* myAddress;
	BOOL inWhois;
	BOOL identifyMsg;
	BOOL identifyCTCP;
	
	IRCChannel* lastSelectedChannel;
	
	NSMutableArray* whoisDialogs;
}

@property (nonatomic, assign) IRCWorld* world;

@property (nonatomic, readonly) NSString* name;
@property (nonatomic, readonly) IRCClientConfig* config;
@property (nonatomic, readonly) IRCISupportInfo* isupport;
@property (nonatomic, readonly) NSMutableArray* channels;

@property (nonatomic, readonly) BOOL connecting;
@property (nonatomic, readonly) BOOL connected;
@property (nonatomic, readonly) BOOL reconnecting;
@property (nonatomic, readonly) BOOL loggedIn;
@property (nonatomic, readonly) NSString* myNick;
@property (nonatomic, readonly) NSString* myAddress;

@property (nonatomic, retain) IRCChannel* lastSelectedChannel;

- (void)setup:(IRCClientConfig*)seed;

- (void)autoConnect:(int)delay;
- (void)onTimer;
- (void)terminate;
- (void)closeDialogs;

- (void)connect;
- (void)disconnect;
- (void)quit;
- (void)cancelReconnect;

- (void)changeNick:(NSString*)newNick;
- (void)joinChannel:(IRCChannel*)channel;
- (void)partChannel:(IRCChannel*)channel;
- (void)sendWhois:(NSString*)nick;
- (void)changeOp:(IRCChannel*)channel users:(NSArray*)users mode:(char)mode value:(BOOL)value;
- (void)kick:(IRCChannel*)channel target:(NSString*)nick;

- (BOOL)sendText:(NSString*)s command:(NSString*)command;
- (void)sendLine:(NSString*)str;
- (void)send:(NSString*)str, ...;

- (IRCChannel*)findChannel:(NSString*)name;
- (int)indexOfTalkChannel;

@end
