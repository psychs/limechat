// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "IRCTreeItem.h"


@implementation IRCTreeItem

@synthesize uid;
@synthesize log;
@synthesize isKeyword;
@synthesize isUnread;
@synthesize isNewTalk;

- (void)dealloc
{
	[log release];
	[super dealloc];
}

- (IRCClient*)client
{
	return nil;
}

- (BOOL)isClient
{
	return NO;
}

- (BOOL)isActive
{
	return NO;
}

- (void)resetState
{
	isKeyword = isUnread = isNewTalk = NO;
}

- (int)numberOfChildren
{
	return 0;
}

- (IRCTreeItem*)childAtIndex:(int)index
{
	return nil;
}

- (NSString*)label
{
	return @"";
}

- (NSString*)name
{
	return @"";
}

@end
