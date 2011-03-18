// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "NickCompletinStatus.h"


@implementation NickCompletinStatus

@synthesize text;
@synthesize range;

- (id)init
{
	self = [super init];
	if (self) {
		[self clear];
	}
	return self;
}

- (void)dealloc
{
	[text release];
	[super dealloc];
}

- (void)clear
{
	self.text = nil;
	range = NSMakeRange(NSNotFound, 0);
}

@end
