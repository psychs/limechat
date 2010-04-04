// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "FileLogger.h"


@interface FileLogger (Private)
- (void)open;
- (NSString*)buildFileName;
@end


@implementation FileLogger

@synthesize client;
@synthesize channel;

- (id)init
{
	if (self = [super init]) {
	}
	return self;
}

- (void)dealloc
{
	[fileName release];
	[file release];
	[super dealloc];
}

- (void)close
{
	if (file) {
		[file closeFile];
		[file release];
		file = nil;
	}
}

- (void)writeLine:(NSString*)s
{
	[self open];
}

- (void)reopenIfNeeded
{
}

- (void)open
{
	[self close];
	
	[fileName release];
}

- (NSString*)buildFileName
{
	[self close];
	
	[fileName release];
}

@end
