// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import <Cocoa/Cocoa.h>
#import "IRCTreeItem.h"
#import "IRCChannelConfig.h"
#import "LogController.h"


@class IRCClient;


@interface IRCChannel : IRCTreeItem
{
	IRCClient* client;
	IRCChannelConfig* config;
	
	NSString* topic;
	
	BOOL isActive;
	BOOL hasOp;
	BOOL namesInit;
	BOOL whoInit;
}

@property (nonatomic, assign) IRCClient* client;
@property (nonatomic, readonly) IRCChannelConfig* config;

@property (nonatomic, assign) NSString* name;
@property (nonatomic, readonly) NSString* password;
@property (nonatomic, readonly) BOOL isChannel;
@property (nonatomic, readonly) BOOL isTalk;
@property (nonatomic, readonly) NSString* channelTypeString;
@property (nonatomic, retain) NSString* topic;
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

- (BOOL)print:(LogLine*)line;

@end
