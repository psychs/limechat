// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "ServerDialog.h"


@interface ServerDialog (Private)
@end


@implementation ServerDialog

@synthesize delegate;
@synthesize parentWindow;
@synthesize uid;
@synthesize config;

- (id)init
{
	if (self = [super init]) {
		[NSBundle loadNibNamed:@"ServerDialog" owner:self];
	}
	return self;
}

- (void)dealloc
{
	[config release];
	[super dealloc];
}

- (void)start
{
	[self show];
}

- (void)show
{
	if (![self.window isVisible]) {
		[self.window center];
	}
	[self.window makeKeyAndOrderFront:nil];
}

#pragma mark -
#pragma mark Actions

- (void)ok:(id)sender
{
	if ([delegate respondsToSelector:@selector(serverDialogOnOK:)]) {
		[delegate serverDialogOnOK:self];
	}
	
	[self.window close];
}

- (void)cancel:(id)sender
{
	[self.window close];
}

- (void)controlTextDidChange:(NSNotification*)note
{
	LOG_METHOD
}

- (void)hostComboChanged:(id)sender
{
	LOG_METHOD
}

- (void)encodingChanged:(id)sender
{
	LOG_METHOD
}

- (void)proxyChanged:(id)sender
{
	LOG_METHOD
}

- (void)addChannel:(id)sender
{
	LOG_METHOD
}

- (void)deleteChannel:(id)sender
{
	LOG_METHOD
}

- (void)editChannel:(id)sender
{
	LOG_METHOD
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification*)note
{
	if ([delegate respondsToSelector:@selector(serverDialogWillClose:)]) {
		[delegate serverDialogWillClose:self];
	}
}

@end
