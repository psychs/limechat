// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "DCCController.h"
#import "IRCWorld.h"
#import "Preferences.h"
#import "DCCReceiver.h"
#import "DCCSender.h"
#import "DCCFileTransferCell.h"
#import "TableProgressIndicator.h"
#import "NSDictionaryHelper.h"


#define TIMER_INTERVAL	1


@interface DCCController (Private)
- (void)reloadReceiverTable;
- (void)reloadSenderTable;
- (void)loadWindowState;
- (void)saveWindowState;
- (void)updateTimer;
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
		
		timer = [Timer new];
		timer.delegate = self;
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
	
	if ([Preferences dccAction] == DCC_AUTO_ACCEPT) {
		[c open];
	}
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
	NSIndexSet* sel = [receiverTable selectedRowIndexes];
	NSUInteger i = [sel firstIndex];
	while (i != NSNotFound) {
		DCCReceiver* e = [receivers objectAtIndex:i];
		[e open];
		
		i = [sel indexGreaterThanIndex:i];
	}
	
	[self reloadReceiverTable];
	[self updateTimer];
}

- (void)stopReceiver:(id)sender
{
	NSIndexSet* sel = [receiverTable selectedRowIndexes];
	NSUInteger i = [sel firstIndex];
	while (i != NSNotFound) {
		DCCReceiver* e = [receivers objectAtIndex:i];
		[e close];
		
		i = [sel indexGreaterThanIndex:i];
	}
	
	[self reloadReceiverTable];
	[self updateTimer];
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
#pragma mark DCCReceiver Delegate

- (void)dccReceiveOnOpen:(DCCReceiver*)sender
{
	if (!loaded) return;
	
	if (!sender.progressBar) {
		TableProgressIndicator* bar = [[TableProgressIndicator new] autorelease];
		[bar setIndeterminate:NO];
		[bar setMinValue:0];
		[bar setMaxValue:sender.size];
		[bar setDoubleValue:sender.processedSize];
		[receiverTable addSubview:bar];
		sender.progressBar = bar;
	}
	
	[self reloadReceiverTable];
	[self updateTimer];
}

- (void)dccReceiveOnClose:(DCCReceiver*)sender
{
	if (!loaded) return;
	
	if (sender.progressBar) {
		[sender.progressBar removeFromSuperview];
		sender.progressBar = nil;
	}
	
	[self reloadReceiverTable];
	[self updateTimer];
}

- (void)dccReceiveOnError:(DCCReceiver*)sender
{
	if (!loaded) return;
	
	[self reloadReceiverTable];
	[self updateTimer];
}

- (void)dccReceiveOnComplete:(DCCReceiver*)sender
{
	if (!loaded) return;

	[self reloadReceiverTable];
	[self updateTimer];
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
		
		c.stringValue = (e.status == DCC_COMPLETE) ? [e.downloadFileName lastPathComponent] : e.fileName;
		c.peerNick = e.peerNick;
		c.size = e.size;
		c.processedSize = e.processedSize;
		c.speed = speed;
		c.timeRemaining = speed > 0 ? ((e.size - e.processedSize)) / speed : 0;
		c.status = e.status;
		c.error = e.error;
		c.icon = e.icon;
		c.progressBar = e.progressBar;
	}
}

#pragma mark -
#pragma mark Timer Delegate

- (void)updateTimer
{
	if (timer.isActive) {
		BOOL foundActive = NO;
		
		for (DCCReceiver* e in receivers) {
			if (e.status == DCC_RECEIVING) {
				foundActive = YES;
				break;
			}
		}
		
		if (!foundActive) {
			for (DCCSender* e in senders) {
				if (e.status == DCC_SENDING) {
					foundActive = YES;
					break;
				}
			}
		}
		
		if (!foundActive) {
			[timer stop];
		}
	}
	else {
		BOOL foundActive = NO;
		
		for (DCCReceiver* e in receivers) {
			if (e.status == DCC_RECEIVING) {
				foundActive = YES;
				break;
			}
		}
		
		if (!foundActive) {
			for (DCCSender* e in senders) {
				if (e.status == DCC_SENDING) {
					foundActive = YES;
					break;
				}
			}
		}
		
		if (foundActive) {
			[timer start:TIMER_INTERVAL];
		}
	}
}

- (void)timerOnTimer:(Timer*)sender
{
	[self reloadReceiverTable];
	[self reloadSenderTable];
	[self updateTimer];
	
	for (DCCReceiver* e in receivers) {
		[e onTimer];
	}
	
	for (DCCSender* e in senders) {
		[e onTimer];
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
