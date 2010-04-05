// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "IRCWorld.h"
#import "IRCClient.h"
#import "IRCChannel.h"
#import "IRCClientConfig.h"


#define AUTO_CONNECT_DELAY	1


@interface IRCWorld (Private)
- (IRCClient*)createClient:(IRCClientConfig*)seed reload:(BOOL)reload;
- (IRCChannel*)createChannel:(IRCChannelConfig*)seed client:(IRCClient*)client reload:(BOOL)reload adjust:(BOOL)adjust;
- (LogController*)createLogWithClient:(IRCClient*)client channel:(IRCChannel*)channel console:(BOOL)console;
@end


@implementation IRCWorld

@synthesize app;
@synthesize window;
@synthesize tree;
@synthesize text;
@synthesize logBase;
@synthesize consoleBase;
@synthesize chatBox;
@synthesize fieldEditor;
@synthesize memberList;
@synthesize menuController;
@synthesize dcc;
@synthesize viewTheme;
@synthesize serverMenu;
@synthesize channelMenu;
@synthesize treeMenu;
@synthesize logMenu;
@synthesize consoleMenu;
@synthesize urlMenu;
@synthesize addrMenu;
@synthesize chanMenu;
@synthesize memberMenu;
@synthesize consoleLog;
@synthesize selectedItem;

@synthesize clients;

- (id)init
{
	if (self = [super init]) {
		clients = [NSMutableArray new];
	}
	return self;
}

- (void)dealloc
{
	[consoleLog release];
	[dummyLog release];
	[config release];
	[clients release];
	[super dealloc];
}

#pragma mark -
#pragma mark Init

- (void)setup:(IRCWorldConfig*)seed
{
	consoleLog = [[self createLogWithClient:nil channel:nil console:YES] retain];
	consoleBase.contentView = consoleLog.view;
	
	dummyLog = [[self createLogWithClient:nil channel:nil console:YES] retain];
	logBase.contentView = dummyLog.view;
	
	config = [seed mutableCopy];
	for (IRCClientConfig* e in config.clients) {
		[self createClient:e reload:YES];
	}
	[config.clients removeAllObjects];
}

- (void)setupTree
{
	LOG_METHOD
	
	[tree setTarget:self];
	[tree setDoubleAction:@selector(outlineViewDoubleClicked:)];
	// @@@drag
	
	IRCClient* client = nil;;
	for (IRCClient* e in clients) {
		if (e.config.autoConnect) {
			client = e;
			break;
		}
	}
	
	if (client) {
		[tree expandItem:client];
		int n = [tree rowForItem:client];
		if (client.channels.count) ++n;
		[tree select:n];
	}
	else if (clients.count > 0) {
		[tree select:0];
	}
	
	[self outlineViewSelectionDidChange:nil];
}

#pragma mark -
#pragma mark Properties

- (id)selected
{
	return nil;
}

#pragma mark -
#pragma mark Utilities

- (void)onTimer
{
	for (IRCClient* c in clients) {
		[c onTimer];
	}
}

- (void)autoConnect
{
	int delay = 0;
	
	for (IRCClient* c in clients) {
		if (c.config.autoConnect) {
			[c autoConnect:delay];
			delay += AUTO_CONNECT_DELAY;
		}
	}
}

- (void)terminate
{
}

- (void)updateTitle
{
}

- (void)updateIcon
{
}

- (void)reloadTree
{
	if (reloadingTree) {
		[tree setNeedsDisplay];
		return;
	}
	
	reloadingTree = YES;
	[tree reloadData];
	reloadingTree = NO;
}

- (void)adjustSelection
{
}

- (IRCClient*)createClient:(IRCClientConfig*)seed reload:(BOOL)reload
{
	IRCClient* c = [[IRCClient new] autorelease];
	c.uid = ++itemId;
	c.world = self;
	c.log = [self createLogWithClient:c channel:nil console:NO];
	[c setup:seed];
	
	for (IRCChannelConfig* e in seed.channels) {
		[self createChannel:e client:c reload:NO adjust:NO];
	}
	
	[clients addObject:c];
	
	if (reload) [self reloadTree];
	
	return c;
}

- (IRCChannel*)createChannel:(IRCChannelConfig*)seed client:(IRCClient*)client reload:(BOOL)reload adjust:(BOOL)adjust
{
	IRCChannel* c = [client findChannel:seed.name];
	if (c) return c;
	
	c = [[IRCChannel new] autorelease];
	c.uid = ++itemId;
	c.client = client;
	[c setup:seed];
	c.log = [self createLogWithClient:client channel:c console:NO];
	
	switch (seed.type) {
		case CHANNEL_TYPE_CHANNEL:
		{
			int n = [client indexOfTalkChannel];
			if (n >= 0) {
				[client.channels insertObject:c atIndex:n];
			}
			else {
				[client.channels addObject:c];
			}
			break;
		}
		default:
			[client.channels addObject:c];
			break;
	}
	
	if (reload) [self reloadTree];
	if (adjust) [self adjustSelection];
	
	return c;
}

- (LogController*)createLogWithClient:(IRCClient*)client channel:(IRCChannel*)channel console:(BOOL)console
{
	LogController* c = [[LogController new] autorelease];
	c.menu = console ? consoleMenu : logMenu;
	c.urlMenu = urlMenu;
	c.addrMenu = addrMenu;
	c.chanMenu = chanMenu;
	c.memberMenu = memberMenu;
	c.world = self;
	c.client = client;
	c.channel = channel;
	c.keyword = nil;	//@@@
	c.maxLines = 300;
	c.theme = nil;	//@@@
	c.overrideFont = nil;	//@@@
	c.console = console;
	//c.initialBackgroundColor = [NSColor blueColor];
	[c setUp];
	
	[c.view setHostWindow:window];
	if (consoleLog) {
		[c.view setTextSizeMultiplier:consoleLog.view.textSizeMultiplier];
	}
	
	return c;
}

#pragma mark -
#pragma mark NSOutlineView Delegate

- (void)outlineViewDoubleClicked:(id)sender
{
	LOG_METHOD
}

- (NSInteger)outlineView:(NSOutlineView *)sender numberOfChildrenOfItem:(id)item
{
	if (!item) return clients.count;
	return [item numberOfChildren];
}

- (BOOL)outlineView:(NSOutlineView *)sender isItemExpandable:(id)item
{
	return [item numberOfChildren] > 0;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
	if (!item) return [clients objectAtIndex:index];
	return [item childAtIndex:index];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	return [item label];
}

- (void)outlineViewSelectionDidChange:(NSNotification *)note
{
	id nextItem = [tree itemAtRow:[tree selectedRow]];
	
	[text focus];
	
	[selectedItem autorelease];
	selectedItem = [nextItem retain];
	
	if (!selectedItem) {
		logBase.contentView = dummyLog.view;
		tree.menu = treeMenu;
		memberList.dataSource = nil;
		memberList.delegate = nil;
		[memberList reloadData];
		return;
	}
	
	[selectedItem resetState];
	
	logBase.contentView = [selectedItem log].view;
	
	if ([selectedItem isClient]) {
		tree.menu = [serverMenu submenu];
		memberList.dataSource = nil;
		memberList.delegate = nil;
		[memberList reloadData];
	}
	else {
		tree.menu = [channelMenu submenu];
		memberList.dataSource = selectedItem;
		memberList.delegate = selectedItem;
		[memberList reloadData];
	}
	
	[memberList deselectAll:nil];
	[memberList scrollRowToVisible:0];
	[[selectedItem log].view clearSel];
	
	[self updateTitle];
	[self reloadTree];
	[self updateIcon];
}

- (void)serverTreeViewAcceptsFirstResponder
{
}

@end
