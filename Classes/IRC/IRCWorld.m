// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "IRCWorld.h"
#import "IRCClient.h"
#import "IRCChannel.h"
#import "IRCClientConfig.h"
#import "Preferences.h"
#import "NSStringHelper.h"


#define AUTO_CONNECT_DELAY				1
#define RECONNECT_AFTER_WAKE_UP_DELAY	8

#define TREE_DRAG_ITEM_TYPE		@"tree"
#define TREE_DRAG_ITEM_TYPES	[NSArray arrayWithObject:TREE_DRAG_ITEM_TYPE]


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
@synthesize growl;
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
		icon = [IconController new];
		clients = [NSMutableArray new];
	}
	return self;
}

- (void)dealloc
{
	[icon release];
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
	[tree registerForDraggedTypes:TREE_DRAG_ITEM_TYPES];
	
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
	[Preferences saveWorld:[self dictionaryValue]];
	[Preferences sync];
}

- (NSMutableDictionary*)dictionaryValue
{
	NSMutableDictionary* dic = [config dictionaryValue];
	
	NSMutableArray* ary = [NSMutableArray array];
	for (IRCClient* u in clients) {
		[ary addObject:[u dictionaryValue]];
	}
	
	[dic setObject:ary forKey:@"clients"];
	return dic;
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

- (void)autoConnect:(BOOL)afterWakeUp
{
	int delay = 0;
	if (afterWakeUp) delay += RECONNECT_AFTER_WAKE_UP_DELAY;
	
	for (IRCClient* c in clients) {
		if (c.config.autoConnect) {
			[c autoConnect:delay];
			delay += AUTO_CONNECT_DELAY;
		}
	}
}

- (void)terminate
{
	for (IRCClient* c in clients) {
		[c terminate];
	}
}

- (void)prepareForSleep
{
	for (IRCClient* c in clients) {
		[c disconnect];
	}
}

- (void)focusInputText
{
	[text focus];
}

- (BOOL)inputText:(NSString*)s command:(NSString*)command
{
	if (!selected) return NO;
	return [[selected client] inputText:s command:command];
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
	BOOL highlight = NO;
	BOOL newTalk = NO;
	
	for (IRCClient* u in clients) {
		if (u.isKeyword) {
			highlight = YES;
			break;
		}
		
		for (IRCChannel* c in u.channels) {
			if (c.isKeyword) {
				highlight = YES;
				break;
			}
			else if (c.isNewTalk) {
				newTalk = YES;
			}
		}
	}
	
	[icon setHighlight:highlight newTalk:newTalk];
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

- (void)preferencesChanged
{
	consoleLog.maxLines = [Preferences maxLogLines];

	for (IRCClient* c in clients) {
		[c preferencesChanged];
	}
}

- (void)notifyOnGrowl:(GrowlNotificationType)type title:(NSString*)title desc:(NSString*)desc context:(id)context
{
	if ([Preferences stopGrowlOnActive] && [NSApp isActive]) return;
	if (![Preferences growlEnabledForEvent:type]) return;
	
	[growl notify:type title:title desc:desc context:context];
}

#pragma mark -
#pragma mark Window Title

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
		NSString* mode = [u.myMode string];
		
		NSMutableString* title = [NSMutableString string];
		if (myNick.length) {
			[title appendFormat:@"(%@)", myNick];
		}
		if (name.length) {
			if (title.length) [title appendString:@" "];
			[title appendString:name];
		}
		if (mode.length) {
			if (title.length) [title appendString:@" "];
			[title appendFormat:@"(%@)", mode];
		}
		[window setTitle:title];
	}
	else {
		IRCClient* u = sel.client;
		IRCChannel* c = (IRCChannel*)sel;
		NSString* myNick = u.myNick;
		
		NSMutableString* title = [NSMutableString string];
		if (myNick.length) {
			[title appendFormat:@"(%@)", myNick];
		}
		
		if (c.isChannel) {
			NSString* chname = c.name;
			NSString* mode = [c.mode titleString];
			int count = [c numberOfMembers];
			NSString* topic = c.topic ?: @"";
			if (topic.length > 25) {
				topic = [topic substringToIndex:25];
				topic = [topic stringByAppendingString:@"…"];
			}
			
			if (title.length) [title appendString:@" "];
			
			IRCUser* m = [c findMember:myNick];
			if (m && m.isOp) {
				[title appendFormat:@"%c", m.mark];
			}
			
			if (chname.length) {
				[title appendString:chname];
			}
			
			if (mode.length) {
				if (count > 1) {
					if (title.length) [title appendString:@" "];
					[title appendFormat:@"(%d,%@)", count, mode];
				}
				else {
					if (title.length) [title appendString:@" "];
					[title appendFormat:@"(%@)", mode];
				}
			}
			else {
				if (count > 1) {
					if (title.length) [title appendString:@" "];
					[title appendFormat:@"(%d)", count];
				}
			}
				
			if (topic.length) {
				if (title.length) [title appendString:@" "];
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
	c.mode.isupport = client.isupport;
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
	
	if (client.isLoggedIn) {
		[c activate];
		
		IRCUser* m;
		m = [[IRCUser new] autorelease];
		m.nick = client.myNick;
		[c addMember:m];
		
		m = [[IRCUser new] autorelease];
		m.nick = c.name;
		[c addMember:m];
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
	else {
		[target.client.channels removeObjectIdenticalTo:target];
	}
	
	[self reloadTree];
	
	if (selected) {
		[tree select:[tree rowForItem:sel]];
	}
}

- (void)destroyClient:(IRCClient*)u
{
	[[u retain] autorelease];
	
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
	[[c retain] autorelease];
	
	[c terminate];
	
	IRCClient* u = c.client;
	if (c.isChannel) {
		if (u.isLoggedIn && c.isActive) {
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
	c.maxLines = [Preferences maxLogLines];
	c.theme = viewTheme;
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
	NSArray* ary = [s componentsSeparatedByString:@" "];
	if (ary.count) {
		NSString* kind = [ary objectAtIndex:0];
		if ([kind isEqualToString:@"client"]) {
			if (ary.count >= 2) {
				int uid = [[ary objectAtIndex:1] intValue];
				IRCClient* u = [self findClientById:uid];
				if (u) {
					[self select:u];
				}
			}
		}
		else if ([kind isEqualToString:@"channel"]) {
			if (ary.count >= 3) {
				int uid = [[ary objectAtIndex:1] intValue];
				int cid = [[ary objectAtIndex:2] intValue];
				IRCChannel* c = [self findChannelByClientId:uid channelId:cid];
				if (c) {
					[self select:c];
				}
			}
		}
	}
}

#pragma mark -
#pragma mark NSOutlineView Delegate

- (void)outlineViewDoubleClicked:(id)sender
{
	if (!selected) return;
	
	IRCClient* u = self.selectedClient;
	IRCChannel* c = self.selectedChannel;
	
	if (!c) {
		if (u.isConnecting || u.isConnected || u.isLoggedIn) {
			if ([Preferences disconnectOnDoubleclick]) {
				[u quit];
			}
		}
		else {
			if ([Preferences connectOnDoubleclick]) {
				[u connect];
			}
		}
	}
	else {
		if (u.isLoggedIn) {
			if (c.isActive) {
				if ([Preferences leaveOnDoubleclick]) {
					[u partChannel:c];
				}
			}
			else {
				if ([Preferences joinOnDoubleclick]) {
					[u joinChannel:c];
				}
			}
		}
	}
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
	IRCTreeItem* i = item;
	
	NSColor* color = nil;
	
	if (i.isKeyword) {
		color = theme.treeHighlightColor;
	}
	else if (i.isNewTalk) {
		color = theme.treeNewTalkColor;
	}
	else if (i.isUnread) {
		color = theme.treeUnreadColor;
	}
	else if (i.isActive) {
		if (i == [tree itemAtRow:[tree selectedRow]]) {
			color = theme.treeSelActiveColor;
		}
		else {
			color = theme.treeActiveColor;
		}
	}
	else {
		if (i == [tree itemAtRow:[tree selectedRow]]) {
			color = theme.treeSelInactiveColor;
		}
		else {
			color = theme.treeInactiveColor;
		}
	}
	
	[cell setTextColor:color];
}

- (void)serverTreeViewAcceptsFirstResponder
{
	[self focusInputText];
}

- (BOOL)outlineView:(NSOutlineView *)sender writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard
{
	if (!items.count) return NO;
	
	NSString* s;
	IRCTreeItem* i = [items objectAtIndex:0];
	if (i.isClient) {
		IRCClient* u = (IRCClient*)i;
		s = [NSString stringWithFormat:@"%d", u.uid];
	}
	else {
		IRCChannel* c = (IRCChannel*)i;
		s = [NSString stringWithFormat:@"%d-%d", c.client.uid, c.uid];
	}
	
	[pboard declareTypes:TREE_DRAG_ITEM_TYPES owner:self];
	[pboard setPropertyList:s forType:TREE_DRAG_ITEM_TYPE];
	return YES;
}

- (IRCTreeItem*)findItemFromInfo:(NSString*)s
{
	if ([s contains:@"-"]) {
		NSArray* ary = [s componentsSeparatedByString:@"-"];
		int uid = [[ary objectAtIndex:0] intValue];
		int cid = [[ary objectAtIndex:1] intValue];
		return [self findChannelByClientId:uid channelId:cid];
	}
	else {
		return [self findClientById:[s intValue]];
	}
}

- (NSDragOperation)outlineView:(NSOutlineView *)sender validateDrop:(id < NSDraggingInfo >)info proposedItem:(id)item proposedChildIndex:(NSInteger)index
{
	if (index < 0) return NSDragOperationNone;
	NSPasteboard* pboard = [info draggingPasteboard];
	if (![pboard availableTypeFromArray:TREE_DRAG_ITEM_TYPES]) return NSDragOperationNone;
	NSString* infoStr = [pboard propertyListForType:TREE_DRAG_ITEM_TYPE];
	if (!infoStr) return NSDragOperationNone;
	IRCTreeItem* i = [self findItemFromInfo:infoStr];
	if (!i) return NSDragOperationNone;
	
	if (i.isClient) {
		if (item) {
			return NSDragOperationNone;
		}
	}
	else {
		if (!item) return NSDragOperationNone;
		IRCChannel* c = (IRCChannel*)i;
		if (c.client != item) return NSDragOperationNone;
		
		IRCClient* toClient = (IRCClient*)item;
		NSArray* ary = toClient.channels;
		NSMutableArray* low = [[[ary subarrayWithRange:NSMakeRange(0, index)] mutableCopy] autorelease];
		NSMutableArray* high = [[[ary subarrayWithRange:NSMakeRange(index, ary.count - index)] mutableCopy] autorelease];
		[low removeObjectIdenticalTo:c];
		[high removeObjectIdenticalTo:c];
		
		if (c.isChannel) {
			// do not allow drop channel between talks
			if (low.count) {
				IRCChannel* prev = [low lastObject];
				if (!prev.isChannel) return NSDragOperationNone;
			}
		}
		else {
			// do not allow drop talk between channels
			if (high.count) {
				IRCChannel* next = [high objectAtIndex:0];
				if (next.isChannel) return NSDragOperationNone;
			}
		}
	}
	
	return NSDragOperationGeneric;
}

- (BOOL)outlineView:(NSOutlineView *)sender acceptDrop:(id < NSDraggingInfo >)info item:(id)item childIndex:(NSInteger)index
{
	if (index < 0) return NO;
	NSPasteboard* pboard = [info draggingPasteboard];
	if (![pboard availableTypeFromArray:TREE_DRAG_ITEM_TYPES]) return NO;
	NSString* infoStr = [pboard propertyListForType:TREE_DRAG_ITEM_TYPE];
	if (!infoStr) return NO;
	IRCTreeItem* i = [self findItemFromInfo:infoStr];
	if (!i) return NO;
	
	if (i.isClient) {
		if (item) return NO;
		
		NSMutableArray* ary = clients;
		NSMutableArray* low = [[[ary subarrayWithRange:NSMakeRange(0, index)] mutableCopy] autorelease];
		NSMutableArray* high = [[[ary subarrayWithRange:NSMakeRange(index, ary.count - index)] mutableCopy] autorelease];
		[low removeObjectIdenticalTo:i];
		[high removeObjectIdenticalTo:i];
		
		[[i retain] autorelease];
		
		[ary removeAllObjects];
		[ary addObjectsFromArray:low];
		[ary addObject:i];
		[ary addObjectsFromArray:high];
		[self reloadTree];
		[self save];
	}
	else {
		if (!item || item != i.client) return NO;
		
		IRCClient* u = (IRCClient*)item;
		NSMutableArray* ary = u.channels;
		NSMutableArray* low = [[[ary subarrayWithRange:NSMakeRange(0, index)] mutableCopy] autorelease];
		NSMutableArray* high = [[[ary subarrayWithRange:NSMakeRange(index, ary.count - index)] mutableCopy] autorelease];
		[low removeObjectIdenticalTo:i];
		[high removeObjectIdenticalTo:i];
		
		[[i retain] autorelease];
		
		[ary removeAllObjects];
		[ary addObjectsFromArray:low];
		[ary addObject:i];
		[ary addObjectsFromArray:high];
		[self reloadTree];
		[self save];
	}
	
	return YES;
}

#pragma mark -
#pragma mark memberListView Delegate

- (void)memberListViewKeyDown:(NSEvent*)e
{
	[self logKeyDown:e];
}

- (void)memberListViewDropFiles:(NSArray*)files row:(NSNumber*)row
{
	IRCClient* u = self.selectedClient;
	IRCChannel* c = self.selectedChannel;
	if (!u || !c) return;
	
	IRCUser* m = [c.members objectAtIndex:[row intValue]];
	if (m) {
		for (NSString* s in files) {
			[dcc addSenderWithUID:u.uid nick:m.nick fileName:s autoOpen:YES];
		}
	}
}

@end
