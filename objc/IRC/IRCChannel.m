// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "IRCChannel.h"


@implementation IRCChannel

@synthesize config;
@synthesize cid;

- (id)init
{
	if (self = [super init]) {
	}
	return self;
}

- (void)dealloc
{
	[config release];
	[super dealloc];
}

- (void)setup:(IRCChannelConfig*)seed
{
}

@end
