// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "IRCChannel.h"


@implementation IRCChannel

@synthesize client;
@synthesize log;

@synthesize config;
@synthesize uid;

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
	[super dealloc];
}

- (void)setup:(IRCChannelConfig*)seed
{
	config = [seed mutableCopy];
}

- (BOOL)isChannel
{
	return config.type == CHANNEL_TYPE_CHANNEL;
}

- (BOOL)isTalk
{
	return config.type == CHANNEL_TYPE_TALK;
}

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

@end
