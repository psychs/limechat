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
}

@property (nonatomic, assign) IRCClient* client;
@property (nonatomic, retain) LogController* log;

@property (nonatomic, readonly) IRCChannelConfig* config;
@property (nonatomic, assign) int uid;

@property (nonatomic, readonly) NSString* name;
@property (nonatomic, readonly) BOOL isChannel;
@property (nonatomic, readonly) BOOL isTalk;
@property (nonatomic, readonly) NSString* typeStr;

- (void)setup:(IRCChannelConfig*)seed;

@end
