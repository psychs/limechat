// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "ChannelDialog.h"
#import "NSWindowHelper.h"
#import "NSStringHelper.h"


@interface ChannelDialog (Private)
- (void)load;
- (void)save;
- (void)update;
@end


@implementation ChannelDialog

@synthesize delegate;
@synthesize window;
@synthesize parentWindow;
@synthesize uid;
@synthesize cid;
@synthesize config;

- (id)init
{
	self = [super init];
	if (self) {
		[NSBundle loadNibNamed:@"ChannelDialog" owner:self];
	}
	return self;
}

- (void)dealloc
{
	[window release];
	[config release];
	[super dealloc];
}

- (void)start
{
	isSheet = NO;
	[self load];
	[self update];
	[self show];
}

- (void)startSheet
{
	isSheet = YES;
	[self load];
	[self update];
	[NSApp beginSheet:window modalForWindow:parentWindow modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void)show
{
	if (![self.window isVisible]) {
		[self.window centerOfWindow:parentWindow];
	}
	[self.window makeKeyAndOrderFront:nil];
}

- (void)close
{
	delegate = nil;
	[self.window close];
}

- (void)sheetDidEnd:(NSWindow*)sender returnCode:(NSInteger)returnCode contextInfo:(void*)contextInfo
{
	[window close];
}

- (void)load
{
	nameText.stringValue = config.name;
	passwordText.stringValue = config.password;
	modeText.stringValue = config.mode;
	topicText.stringValue = config.topic;
	
	autoJoinCheck.state = config.autoJoin;
	consoleCheck.state = config.logToConsole;
	growlCheck.state = config.growl;
}

- (void)save
{
	config.name = nameText.stringValue;
	config.password = passwordText.stringValue;
	config.mode = modeText.stringValue;
	config.topic = topicText.stringValue;

	config.autoJoin = autoJoinCheck.state;
	config.logToConsole = consoleCheck.state;
	config.growl = growlCheck.state;
	
	if (![config.name isChannelName]) {
		config.name = [@"#" stringByAppendingString:config.name];
	}
}

- (void)update
{
	if (cid < 0) {
		[self.window setTitle:@"New Channel"];
	}
	else {
		[nameText setEditable:NO];
		[nameText setSelectable:NO];
		[nameText setBezeled:NO];
		[nameText setDrawsBackground:NO];
	}
	
	NSString* s = nameText.stringValue;
	[okButton setEnabled:s.length > 0];
}

- (void)controlTextDidChange:(NSNotification*)note
{
	[self update];
}

#pragma mark -
#pragma mark Actions

- (void)ok:(id)sender
{
	[self save];
	
	if ([delegate respondsToSelector:@selector(channelDialogOnOK:)]) {
		[delegate channelDialogOnOK:self];
	}
	
	[self cancel:nil];
}

- (void)cancel:(id)sender
{
	if (isSheet) {
		[NSApp endSheet:window];
	}
	else {
		[self.window close];
	}
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification*)note
{
	if ([delegate respondsToSelector:@selector(channelDialogWillClose:)]) {
		[delegate channelDialogWillClose:self];
	}
}

@end
