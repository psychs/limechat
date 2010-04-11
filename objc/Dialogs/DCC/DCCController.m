// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "DCCController.h"
#import "IRCWorld.h"
#import "Preferences.h"
#import "NSDictionaryHelper.h"


@interface DCCController (Private)
- (void)loadWindowState;
- (void)saveWindowState;
@end


@implementation DCCController

@synthesize delegate;
@synthesize world;
@synthesize mainWindow;

- (id)init
{
	if (self = [super init]) {
		receivers = [NSMutableArray new];
		senders = [NSMutableArray new];
	}
	return self;
}

- (void)dealloc
{
	[receivers release];
	[senders release];
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
		[self loadWindowState];
	}
}

- (void)close
{
	if (!loaded) return;
	
	[self.window close];
}

- (void)terminate
{
	[self close];
}

- (void)loadWindowState
{
	NSDictionary* dic = [Preferences loadWindowStateWithName:@"dcc_window"];
	if (dic) {
		int x = [dic intForKey:@"x"];
		int y = [dic intForKey:@"y"];
		int w = [dic intForKey:@"w"];
		int h = [dic intForKey:@"h"];
		NSRect r = NSMakeRect(x, y, w, h);
		[self.window setFrame:r display:NO];
		[splitter setPosition:[dic intForKey:@"split"]];
		[self.window makeKeyAndOrderFront:nil];
	}
	else {
		[self.window setFrame:NSMakeRect(0, 0, 350, 300) display:NO];
		[self.window center];
		[splitter setPosition:100];
		[self.window makeKeyAndOrderFront:nil];
	}
}

- (void)saveWindowState
{
	NSMutableDictionary* dic = [NSMutableDictionary dictionary];
	
	NSRect rect = self.window.frame;
	[dic setInt:rect.origin.x forKey:@"x"];
	[dic setInt:rect.origin.y forKey:@"y"];
	[dic setInt:rect.size.width forKey:@"w"];
	[dic setInt:rect.size.height forKey:@"h"];
	[dic setInt:splitter.position forKey:@"split"];
	
	[Preferences saveWindowState:dic name:@"dcc_window"];
	[Preferences sync];
}

#pragma mark -
#pragma mark Actions

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
	NSInteger tag = item.tag;
	switch (tag) {
		case 3001:
		case 3002:
		case 3003:
		case 3004:
		case 3005:
		case 3006:
		case 3101:
		case 3102:
		case 3103:
			return YES;
	}
	
	return NO;
}

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
#pragma mark NSTableViwe Delegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)sender
{
	if (sender == senderTable) {
		return senders.count;
	}
	else {
		return receivers.count;
	}
}

- (id)tableView:(NSTableView *)sender objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
	return @"";
}

- (void)tableView:(NSTableView *)sender willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
	NSArray* list;
	if (sender == senderTable) {
		list = senders;
	}
	else {
		list = receivers;
	}
	
	if (row < 0 || list.count <= row) return;
	
	
}

#pragma mark -
#pragma mark DialogWindow Delegate

- (void)dialogWindowEscape
{
	[self.window close];
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification*)note
{
	[self saveWindowState];
}

@end
