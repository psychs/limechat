// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "IRCClient.h"
#import "IRCWorld.h"


@implementation IRCClient

@synthesize world;
@synthesize log;

@synthesize config;
@synthesize channels;
@synthesize uid;

- (id)init
{
	if (self = [super init]) {
		channels = [NSMutableArray new];
	}
	return self;
}

- (void)dealloc
{
	[log release];
	[config release];
	[channels release];
	[super dealloc];
}

- (void)setup:(IRCClientConfig*)seed
{
}

@end
