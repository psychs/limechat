// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "DCCController.h"
#import "IRCWorld.h"


@interface DCCController (Private)
@end


@implementation DCCController

@synthesize delegate;
@synthesize world;

- (id)init
{
	if (self = [super init]) {
	}
	return self;
}

- (void)dealloc
{
	[super dealloc];
}

- (void)show
{
	if (!loaded) {
		loaded = YES;
		[NSBundle loadNibNamed:@"DCCDialog" owner:self];
		[splitter setFixedViewIndex:1];
	}
	
	if (![self.window isVisible]) {
		[self.window center];
	}
	[self.window makeKeyAndOrderFront:nil];
}

#pragma mark -
#pragma mark Actions

- (void)onClear:(id)sender
{
	LOG_METHOD
}

- (void)startReceiver:(id)sender
{
	LOG_METHOD
}

- (void)stopReceiver:(id)sender
{
	LOG_METHOD
}

- (void)deleteReceiver:(id)sender
{
	LOG_METHOD
}

- (void)openReceiver:(id)sender
{
	LOG_METHOD
}

- (void)revealReceivedFileInFinder:(id)sender
{
	LOG_METHOD
}

- (void)startSender:(id)sender
{
	LOG_METHOD
}

- (void)stopSender:(id)sender
{
	LOG_METHOD
}

- (void)deleteSender:(id)sender
{
	LOG_METHOD
}

#pragma mark -
#pragma mark DialogWindow Delegate

- (void)dialogWindowEscape
{
	[self.window close];
}

@end
