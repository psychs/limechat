// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

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
