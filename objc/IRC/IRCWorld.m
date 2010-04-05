// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "IRCWorld.h"


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
	[clients release];
	[super dealloc];
}

#pragma mark -
#pragma mark Init

- (void)setup:(id)config
{
	LOG_METHOD
	
	LOG(@"%@", config);
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
