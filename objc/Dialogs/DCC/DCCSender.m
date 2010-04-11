// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "DCCSender.h"


@interface DCCSender (Private)
@end


@implementation DCCSender

@synthesize delegate;
@synthesize uid;
@synthesize peerNick;
@synthesize port;
@synthesize fileName;
@synthesize size;
@synthesize processedSize;
@synthesize status;
@synthesize error;
@synthesize icon;
@synthesize progressBar;

- (id)init
{
	if (self = [super init]) {
	}
	return self;
}

- (void)dealloc
{
	[peerNick release];
	[fileName release];
	[error release];
	[icon release];
	[progressBar release];
	[super dealloc];
}

- (void)open
{
}

- (void)close
{
}

- (void)onTimer
{
}

@end
