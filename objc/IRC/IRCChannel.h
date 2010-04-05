// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import <Cocoa/Cocoa.h>
#import "IRCTreeItem.h"
#import "IRCChannelConfig.h"
#import "LogController.h"


@class IRCClient;


@interface IRCChannel : NSObject <IRCTreeItem>
{
	IRCClient* client;
	LogController* log;
	
	IRCChannelConfig* config;
	int uid;
	
	NSString* topic;
	
	BOOL isKeyword;
	BOOL isUnread;
	BOOL isNewTalk;
	BOOL isActive;
	BOOL hasOp;
	BOOL namesInit;
	BOOL whoInit;
}

@property (nonatomic, assign) IRCClient* client;
@property (nonatomic, retain) LogController* log;

@property (nonatomic, readonly) IRCChannelConfig* config;
@property (nonatomic, assign) int uid;

@property (nonatomic, assign) NSString* name;
@property (nonatomic, readonly) NSString* password;
@property (nonatomic, readonly) BOOL isChannel;
@property (nonatomic, readonly) BOOL isTalk;
@property (nonatomic, readonly) NSString* typeStr;
@property (nonatomic, retain) NSString* topic;
@property (nonatomic, assign) BOOL isKeyword;
@property (nonatomic, assign) BOOL isUnread;
@property (nonatomic, assign) BOOL isNewTalk;
@property (nonatomic, assign) BOOL isActive;
@property (nonatomic, assign) BOOL hasOp;
@property (nonatomic, assign) BOOL namesInit;
@property (nonatomic, assign) BOOL whoInit;

- (void)setup:(IRCChannelConfig*)seed;
- (void)updateConfig:(IRCChannelConfig*)seed;
- (void)updateAutoOp:(IRCChannelConfig*)seed;

- (void)terminate;
- (void)activate;
- (void)deactivate;
- (void)closeDialogs;

@end
