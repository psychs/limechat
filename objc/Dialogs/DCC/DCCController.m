// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "DCCController.h"
#import "IRCWorld.h"
#import "Preferences.h"
#import "DCCReceiver.h"
#import "DCCSender.h"
#import "DCCFileTransferCell.h"
#import "NSDictionaryHelper.h"


@interface DCCController (Private)
- (void)reloadReceiverTable;
- (void)reloadSenderTable;
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

- (void)show:(BOOL)key
{
	if (!loaded) {
		loaded = YES;
		[NSBundle loadNibNamed:@"DCCDialog" owner:self];
		[splitter setFixedViewIndex:1];
		
		DCCFileTransferCell* senderCell = [[DCCFileTransferCell new] autorelease];
		[[[senderTable tableColumns] objectAtIndex:0] setDataCell:senderCell];
		
		DCCFileTransferCell* receiverCell = [[DCCFileTransferCell new] autorelease];
		[[[receiverTable tableColumns] objectAtIndex:0] setDataCell:receiverCell];
		
		for (DCCReceiver* e in receivers) {
		}
		
		for (DCCSender* e in senders) {
		}
	}
	
	if (![self.window isVisible]) {
		[self loadWindowState];
	}
	
	if (key) {
		[self.window makeKeyAndOrderFront:nil];
	}
	else {
		[self.window orderFront:nil];
	}
	
	[self reloadReceiverTable];
	[self reloadSenderTable];
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

- (void)addReceiverWithUID:(int)uid nick:(NSString*)nick host:(NSString*)host port:(int)port path:(NSString*)path fileName:(NSString*)fileName size:(long long)size
{
	DCCReceiver* c = [[DCCReceiver new] autorelease];
	c.delegate = self;
	c.uid = uid;
	c.peerNick = nick;
	c.host = host;
	c.port = port;
	c.path = path;
	c.fileName = fileName;
	c.size = size;
	[receivers insertObject:c atIndex:0];
	
	[self show:NO];
}

- (void)reloadReceiverTable
{
	[receiverTable reloadData];
}

- (void)reloadSenderTable
{
	[senderTable reloadData];
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
	}
	else {
		[self.window setFrame:NSMakeRect(0, 0, 350, 300) display:NO];
		[self.window center];
		[splitter setPosition:100];
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

- (void)tableView:(NSTableView *)sender willDisplayCell:(DCCFileTransferCell*)c forTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
	if (sender == senderTable) {
		if (row < 0 || senders.count <= row) return;
	}
	else {
		if (row < 0 || receivers.count <= row) return;
		
		DCCReceiver* e = [receivers objectAtIndex:row];
		double speed = e.speed;
		
		c.stringValue = (e.status == DCC_COMPLETE) ? e.downloadFileName : e.fileName;
		c.peerNick = e.peerNick;
		c.size = e.size;
		c.processedSize = e.processedSize;
		c.speed = speed;
		c.timeRemaining = speed > 0 ? (e.size - e.processedSize) / speed : 0;
		c.status = e.status;
		c.error = e.error;
		c.icon = e.icon;
		c.progressBar = e.progressBar;
	}
}

#pragma mark -
#pragma mark DialogWindow Delegate

- (void)dialogWindowEscape
{
	[self.window close];
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowDidBecomeMain:(NSNotification *)note
{
	[self reloadReceiverTable];
	[self reloadSenderTable];
}

- (void)windowDidResignMain:(NSNotification *)note
{
	[self reloadReceiverTable];
	[self reloadSenderTable];
}

- (void)windowWillClose:(NSNotification*)note
{
	[self saveWindowState];
}

@end
