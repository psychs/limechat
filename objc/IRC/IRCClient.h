// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import <Cocoa/Cocoa.h>
#import "IRCTreeItem.h"
#import "IRCClientConfig.h"
#import "LogController.h"


@class IRCWorld;


@interface IRCClient : NSObject <IRCTreeItem>
{
	IRCWorld* world;
	LogController* log;
	
	IRCClientConfig* config;
	NSMutableArray* channels;
	int uid;
}

@property (nonatomic, assign) IRCWorld* world;
@property (nonatomic, retain) LogController* log;

@property (nonatomic, readonly) IRCClientConfig* config;
@property (nonatomic, readonly) NSMutableArray* channels;
@property (nonatomic, assign) int uid;

- (void)setup:(IRCClientConfig*)seed;

@end
