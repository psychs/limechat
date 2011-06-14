// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "IRCPrefix.h"


@implementation IRCPrefix

@synthesize raw;
@synthesize nick;
@synthesize user;
@synthesize address;
@synthesize isServer;

- (id)init
{
	self = [super init];
	if (self) {
		raw = @"";
		nick = @"";
		user = @"";
		address = @"";
	}
	return self;
}

- (void)dealloc
{
	[raw release];
	[nick release];
	[user release];
	[address release];
	[super dealloc];
}

@end
