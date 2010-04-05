// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "IRCWorld.h"
#import "IRCClient.h"
#import "IRCChannel.h"


@interface IRCWorld (Private)
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
	if (consoleLog) [c.view setTextSizeMultiplier:consoleLog.view.textSizeMultiplier];
	return c;
}

#pragma mark -
#pragma mark NSOutlineView Delegate

- (NSInteger)outlineView:(NSOutlineView *)sender numberOfChildrenOfItem:(id)item
{
	return 1;
}

- (BOOL)outlineView:(NSOutlineView *)sender isItemExpandable:(id)item
{
	return NO;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
	return @"test";
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	return @"test";
}

- (void)serverTreeViewAcceptsFirstResponder
{
	LOG_METHOD
}

@end
