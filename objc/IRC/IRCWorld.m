// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "IRCWorld.h"
#import "IRCClient.h"
#import "IRCChannel.h"
#import "IRCClientConfig.h"


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
	consoleLog = [self createLogWithClient:nil channel:nil console:YES];
	[consoleBase setContentView:consoleLog.view];
	
	dummyLog = [self createLogWithClient:nil channel:nil console:YES];
	[logBase setContentView:dummyLog.view];
	
	config = [seed mutableCopy];
	for (IRCClientConfig* e in config.clients) {
		[self createClient:e reload:YES];
	}
	[config.clients removeAllObjects];
}

- (void)setupTree
{
	LOG_METHOD
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
}

- (void)autoConnect
{
	LOG_METHOD
}

- (void)terminate
{
	LOG_METHOD
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
	LOG_METHOD
}

- (IRCClient*)createClient:(IRCClientConfig*)seed reload:(BOOL)reload
{
	IRCClient* c = [[IRCClient new] autorelease];
	c.uid = ++itemId;
	c.world = self;
	c.log = [self createLogWithClient:c channel:nil console:NO];
	[c setup:seed];
	
	for (IRCChannelConfig* e in seed.channels) {
		;
	}
	
	[clients addObject:c];
	
	if (reload) {
		[self reloadTree];
	}
	
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
	
	if (reload) {
		[self reloadTree];
	}
	
	if (adjust) {
		[self adjustSelection];
	}
	
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

- (void)serverTreeViewAcceptsFirstResponder
{
	LOG_METHOD
}

@end
