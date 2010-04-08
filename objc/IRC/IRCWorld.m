// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "IRCWorld.h"
#import "IRCClient.h"
#import "IRCChannel.h"
#import "IRCClientConfig.h"
#import "Preferences.h"


#define AUTO_CONNECT_DELAY	1


@interface IRCWorld (Private)
- (void)storePreviousSelection;
- (void)changeInputTextTheme;
- (void)changeTreeTheme;
- (void)changeMemberListTheme;
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
@synthesize selected;

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
	[selected release];
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
	
	[self changeInputTextTheme];
	[self changeTreeTheme];
	[self changeMemberListTheme];
}

- (void)setupTree
{
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

- (void)save
{
}

#pragma mark -
#pragma mark Properties

- (IRCClient*)selectedClient
{
	if (!selected) return nil;
	return [selected client];
}

- (IRCChannel*)selectedChannel
{
	if (!selected) return nil;
	if ([selected isClient]) return nil;
	return (IRCChannel*)selected;
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

- (void)focusInputText
{
	[text focus];
}

- (BOOL)sendText:(NSString*)s command:(NSString*)command
{
	if (!selected) return NO;
	return [[selected client] sendText:s command:command];
}

- (void)markAllAsRead
{
	for (IRCClient* u in clients) {
		u.isUnread = NO;
		for (IRCChannel* c in u.channels) {
			c.isUnread = NO;
		}
	}
	[self reloadTree];
}

- (void)markAllScrollbacks
{
	for (IRCClient* u in clients) {
		[u.log mark];
		for (IRCChannel* c in u.channels) {
			[c.log mark];
		}
	}
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

- (void)expandClient:(IRCClient*)client
{
	[tree expandItem:client];
}

- (void)adjustSelection
{
	int row = [tree selectedRow];
	if (0 <= row && selected && selected != [tree itemAtRow:row]) {
		[tree select:[tree rowForItem:selected]];
		[self reloadTree];
	}
}

- (void)storePreviousSelection
{
	if (!selected) {
		previousSelectedClientId = 0;
		previousSelectedChannelId = 0;
	}
	else if (selected.isClient) {
		previousSelectedClientId = selected.uid;
		previousSelectedChannelId = 0;
	}
	else {
		previousSelectedClientId = selected.client.uid;
		previousSelectedChannelId = selected.uid;
	}
}

- (void)selectPreviousItem
{
	if (!previousSelectedClientId && !previousSelectedClientId) return;
	
	int uid = previousSelectedClientId;
	int cid = previousSelectedChannelId;
	
	IRCTreeItem* item;
	
	if (cid) {
		item = [self findChannelByClientId:uid channelId:cid];
	}
	else {
		item = [self findClientById:uid];
	}
	
	if (item) {
		[self select:item];
	}
}

- (void)updateTitle
{
	if (!selected) {
		[window setTitle:@"LimeChat"];
		return;
	}
	
	IRCTreeItem* sel = selected;
	if (sel.isClient) {
		IRCClient* u = (IRCClient*)sel;
		NSString* myNick = u.myNick;
		NSString* name = u.config.name;
		
		NSMutableString* title = [NSMutableString string];
		if (myNick.length) {
			[title appendFormat:@"(%@)", myNick];
		}
		if (name.length) {
			if (title.length > 0) [title appendString:@" "];
			[title appendString:name];
		}
		[window setTitle:title];
	}
	else {
		IRCClient* u = sel.client;
		IRCChannel* c = (IRCChannel*)sel;
		NSString* myNick = u.myNick;
		NSString* chname = c.name;
		int count = [c numberOfMembers];
		NSString* topic = c.topic ?: @"";
		if (topic.length > 25) {
			topic = [topic substringToIndex:25];
			topic = [topic stringByAppendingString:@"…"];
		}
		
		NSMutableString* title = [NSMutableString string];
		if (myNick.length) {
			[title appendFormat:@"(%@)", myNick];
		}
		
		if (c.isChannel) {
			if (title.length > 0) [title appendString:@" "];
			
			IRCUser* m = [c findMember:myNick];
			if (m && m.isOp) {
				[title appendFormat:@"%c", m.mark];
			}
			
			if (chname.length) {
				[title appendString:chname];
			}
			
			if (count > 1) {
				if (title.length > 0) [title appendString:@" "];
				[title appendFormat:@"(%d)", count];
			}
				
			if (topic.length) {
				if (title.length > 0) [title appendString:@" "];
				[title appendString:topic];
			}
		}
		[window setTitle:title];
	}
}

- (void)updateClientTitle:(IRCClient*)client
{
	if (!client || !selected) return;
	if (selected == client) {
		[self updateTitle];
	}
}

- (void)updateChannelTitle:(IRCChannel*)channel
{
	if (!channel || !selected) return;
	if (selected == channel) {
		[self updateTitle];
	}
}

#pragma mark -
#pragma mark Tree Items

- (IRCClient*)findClient:(NSString*)name
{
	for (IRCClient* u in clients) {
		if ([u.name isEqualToString:name]) {
			return u;
		}
	}
	return nil;
}

- (IRCClient*)findClientById:(int)uid
{
	for (IRCClient* u in clients) {
		if (u.uid == uid) {
			return u;
		}
	}
	return nil;
}

- (IRCChannel*)findChannelByClientId:(int)uid channelId:(int)cid
{
	for (IRCClient* u in clients) {
		if (u.uid == uid) {
			for (IRCChannel* c in u.channels) {
				if (c.uid == cid) {
					return c;
				}
			}
			break;
		}
	}
	return nil;
}

- (void)select:(id)item
{
	if (selected == item) return;
	
	[self storePreviousSelection];
	[self focusInputText];
	
	if (!item) {
		self.selected = nil;
		
		[logBase setContentView:dummyLog.view];
		memberList.dataSource = nil;
		[memberList reloadData];
		tree.menu = treeMenu;
		return;
	}
	
	BOOL isClient = [item isClient];
	IRCClient* client = (IRCClient*)[item client];
	
	if (!isClient) [tree expandItem:client];
	
	int i = [tree rowForItem:item];
	if (i < 0) return;
	[tree select:i];
	
	client.lastSelectedChannel = isClient ? nil : (IRCChannel*)item;
}

- (void)selectChannelAt:(int)n
{
	IRCClient* c = self.selectedClient;
	if (!c) return;
	if (n == 0) {
		[self select:c];
	}
	else {
		--n;
		if (0 <= n && n < c.channels.count) {
			IRCChannel* e = [c.channels objectAtIndex:n];
			[self select:e];
		}
	}
}

- (void)selectClientAt:(int)n
{
	if (0 <= n && n < clients.count) {
		IRCClient* c = [clients objectAtIndex:n];
		IRCChannel* e = c.lastSelectedChannel;
		if (e) {
			[self select:e];
		}
		else {
			[self select:c];
		}
	}
}

#pragma mark -
#pragma mark Theme

- (void)reloadTheme
{
	viewTheme.name = [Preferences themeName];
	
	NSMutableArray* logs = [NSMutableArray array];
	[logs addObject:consoleLog];
	for (IRCClient* u in clients) {
		[logs addObject:u.log];
		for (IRCChannel* c in u.channels) {
			[logs addObject:c.log];
		}
	}
	
	for (LogController* log in logs) {
		[log reloadTheme];
	}
	
	[self changeInputTextTheme];
	[self changeTreeTheme];
	[self changeMemberListTheme];
}

- (void)changeInputTextTheme
{
	OtherTheme* theme = viewTheme.other;
	
	[fieldEditor setInsertionPointColor:theme.inputTextColor];
	[text setTextColor:theme.inputTextColor];
	[text setBackgroundColor:theme.inputTextBgColor];
	[chatBox setInputTextFont:theme.inputTextFont];
}

- (void)changeTreeTheme
{
	OtherTheme* theme = viewTheme.other;
	
	[tree setFont:theme.treeFont];
	[tree themeChanged];
	[tree setNeedsDisplay];
}

- (void)changeMemberListTheme
{
	OtherTheme* theme = viewTheme.other;
	
	[memberList setFont:theme.memberListFont];
	[[[[memberList tableColumns] objectAtIndex:0] dataCell] themeChanged];
	[memberList themeChanged];
	[memberList setNeedsDisplay];
}

- (void)changeTextSize:(BOOL)bigger
{
	[consoleLog changeTextSize:bigger];
	
	for (IRCClient* u in clients) {
		[u.log changeTextSize:bigger];
		for (IRCChannel* c in u.channels) {
			[c.log changeTextSize:bigger];
		}
	}
}

#pragma mark -
#pragma mark Factory

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

- (IRCChannel*)createTalk:(NSString*)nick client:(IRCClient*)client
{
	IRCChannelConfig* seed = [[IRCChannelConfig new] autorelease];
	seed.name = nick;
	seed.type = CHANNEL_TYPE_TALK;
	IRCChannel* c = [self createChannel:seed client:client reload:YES adjust:YES];
	
	if (client.loggedIn) {
		[c activate];
		
		// @@@ add members
	}
	
	return c;
}

- (void)selectOtherAndDestroy:(IRCTreeItem*)target
{
	IRCTreeItem* sel = nil;
	int i;
	
	if (target.isClient) {
		i = [clients indexOfObjectIdenticalTo:target];
		int n = i + 1;
		if (0 <= n && n < clients.count) {
			sel = [clients objectAtIndex:n];
		}
		i = [tree rowForItem:target];
	}
	else {
		i = [tree rowForItem:target];
		int n = i + 1;
		if (0 <= n && n < [tree numberOfRows]) {
			sel = [tree itemAtRow:n];
		}
		if (sel && sel.isClient) {
			// we don't want to change clients when closing a channel
			n = i - 1;
			if (0 <= n && n < [tree numberOfRows]) {
				sel = [tree itemAtRow:n];
			}
		}
	}
	
	if (sel) {
		[self select:sel];
	}
	else {
		int n = i - 1;
		if (0 <= n && n < [tree numberOfRows]) {
			sel = [tree itemAtRow:n];
		}
		[self select:sel];
	}
	
	if (target.isClient) {
		IRCClient* u = (IRCClient*)target;
		for (IRCChannel* c in u.channels) {
			[c closeDialogs];
		}
		[clients removeObjectIdenticalTo:target];
	}
	
	[self reloadTree];
	
	if (selected) {
		[tree select:[tree rowForItem:sel]];
	}
}

- (void)destroyClient:(IRCClient*)u
{
	[u terminate];
	[u disconnect];
	
	if (selected && selected.client == u) {
		[self selectOtherAndDestroy:u];
	}
	else {
		[clients removeObjectIdenticalTo:u];
		[self reloadTree];
		[self adjustSelection];
	}
}

- (void)destroyChannel:(IRCChannel*)c
{
	[c terminate];
	
	IRCClient* u = c.client;
	if (c.isChannel) {
		if (u.loggedIn && c.isActive) {
			[u partChannel:c];
		}
	}
	
	if (u.lastSelectedChannel == c) {
		u.lastSelectedChannel = nil;
	}
	
	if (selected == c) {
		[self selectOtherAndDestroy:c];
	}
	else {
		[u.channels removeObjectIdenticalTo:c];
		[self reloadTree];
		[self adjustSelection];
	}
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
	c.maxLines = 300;
	c.theme = viewTheme;
	c.overrideFont = nil;	//@@@
	c.console = console;
	c.initialBackgroundColor = [viewTheme.other inputTextBgColor];
	[c setUp];
	
	[c.view setHostWindow:window];
	if (consoleLog) {
		[c.view setTextSizeMultiplier:consoleLog.view.textSizeMultiplier];
	}
	
	return c;
}

#pragma mark -
#pragma mark Log Delegate

- (void)logKeyDown:(NSEvent*)e
{
	[window makeFirstResponder:text];
	[self focusInputText];
	
	switch (e.keyCode) {
		case KEY_RETURN:
		case KEY_ENTER:
			return;
	}
	
	[window sendEvent:e];
}

- (void)logDoubleClick:(NSString*)s
{
	LOG(@"logDoubleClick: %@", s);
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

- (void)outlineViewSelectionIsChanging:(NSNotification *)note
{
	[self storePreviousSelection];
}

- (void)outlineViewSelectionDidChange:(NSNotification *)note
{
	id nextItem = [tree itemAtRow:[tree selectedRow]];
	
	[text focus];
	
	self.selected = nextItem;
	
	if (!selected) {
		logBase.contentView = dummyLog.view;
		tree.menu = treeMenu;
		memberList.dataSource = nil;
		memberList.delegate = nil;
		[memberList reloadData];
		return;
	}
	
	[selected resetState];
	
	logBase.contentView = [[selected log] view];
	
	if ([selected isClient]) {
		tree.menu = [serverMenu submenu];
		memberList.dataSource = nil;
		memberList.delegate = nil;
		[memberList reloadData];
	}
	else {
		tree.menu = [channelMenu submenu];
		memberList.dataSource = selected;
		memberList.delegate = selected;
		[memberList reloadData];
	}
	
	[memberList deselectAll:nil];
	[memberList scrollRowToVisible:0];
	[selected.log.view clearSelection];
	
	[self updateTitle];
	[self reloadTree];
	[self updateIcon];
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	OtherTheme* theme = viewTheme.other;
	
	[cell setTextColor:theme.treeActiveColor];
}

- (void)serverTreeViewAcceptsFirstResponder
{
}

#pragma mark -
#pragma mark memberListView Delegate

- (void)memberListViewKeyDown:(NSEvent*)e
{
	[self logKeyDown:e];
}

- (void)memberListViewDropFiles:(NSArray*)files row:(NSNumber*)row
{
	LOG_METHOD
}

@end
