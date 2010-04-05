// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "IRCChannel.h"


@implementation IRCChannel

@synthesize client;
@synthesize log;

@synthesize config;
@synthesize uid;

@synthesize topic;
@synthesize isKeyword;
@synthesize isUnread;
@synthesize isNewTalk;
@synthesize isActive;
@synthesize hasOp;
@synthesize namesInit;
@synthesize whoInit;

- (id)init
{
	if (self = [super init]) {
	}
	return self;
}

- (void)dealloc
{
	[log release];
	[config release];
	[topic release];
	[super dealloc];
}

#pragma mark -
#pragma mark Init

- (void)setup:(IRCChannelConfig*)seed
{
	config = [seed mutableCopy];
}

- (void)updateConfig:(IRCChannelConfig*)seed
{
	[config release];
	config = [seed mutableCopy];
}

- (void)updateAutoOp:(IRCChannelConfig*)seed
{
	[config.autoOp removeAllObjects];
	[config.autoOp addObjectsFromArray:seed.autoOp];
}

#pragma mark -
#pragma mark Properties

- (NSString*)name
{
	return config.name;
}

- (void)setName:(NSString *)value
{
	config.name = value;
}

- (NSString*)password
{
	return config.password ?: @"";
}

- (BOOL)isChannel
{
	return config.type == CHANNEL_TYPE_CHANNEL;
}

- (BOOL)isTalk
{
	return config.type == CHANNEL_TYPE_TALK;
}

- (NSString*)typeStr
{
	switch (config.type) {
		case CHANNEL_TYPE_CHANNEL: return @"channel";
		case CHANNEL_TYPE_TALK: return @"talk";
	}
	return nil;
}

#pragma mark -
#pragma mark Utilities

- (void)resetState
{
	isKeyword = isUnread = isNewTalk = NO;
}

- (void)terminate
{
}

- (void)activate
{
	isActive = YES;
	hasOp = NO;
	self.topic = nil;
	namesInit = NO;
	whoInit = NO;
}

- (void)deactivate
{
	isActive = NO;
	hasOp = NO;
}

- (void)closeDialogs
{
}



#pragma mark -
#pragma mark IRCTreeItem

- (int)numberOfChildren
{
	return 0;
}

- (id)childAtIndex:(int)index
{
	return nil;
}

- (NSString*)label
{
	return config.name;
}

- (BOOL)isClient
{
	return NO;
}

@end
