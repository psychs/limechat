// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "TimerCommand.h"


@implementation TimerCommand

@synthesize time;
@synthesize cid;
@synthesize input;

- (id)init
{
	if (self = [super init]) {
	}
	return self;
}

- (void)dealloc
{
	[input release];
	[super dealloc];
}

@end
