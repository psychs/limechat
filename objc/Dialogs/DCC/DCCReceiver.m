// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "DCCReceiver.h"


@interface DCCReceiver (Private)
- (void)openFile;
- (void)closeFile;
@end


@implementation DCCReceiver

@synthesize delegate;
@synthesize uid;
@synthesize peerNick;
@synthesize host;
@synthesize port;
@synthesize size;
@synthesize processedSize;
@synthesize version;
@synthesize status;
@synthesize error;
@synthesize path;
@synthesize fileName;
@synthesize downloadFileName;
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
	[host release];
	[error release];
	[path release];
	[fileName release];
	[downloadFileName release];
	[icon release];
	[progressBar release];
	[super dealloc];
}

- (void)setPath:(NSString *)value
{
	if (path != value) {
		[path release];
		path = [[value stringByExpandingTildeInPath] retain];
	}
}

- (void)setFileName:(NSString *)value
{
	if (fileName != value) {
		[fileName release];
		fileName = [value retain];
		
		[icon release];
		icon = [[[NSWorkspace sharedWorkspace] iconForFile:[fileName pathExtension]] retain];
	}
}

- (void)open
{
}

- (void)close
{
}

- (void)openFile
{
}

- (void)closeFile
{
}

@end
