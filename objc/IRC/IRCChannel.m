// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "IRCChannel.h"
#import "IRCClient.h"
#import "IRCWorld.h"
#import "MemberListViewCell.h"
#import "NSStringHelper.h"


@interface IRCChannel (Private)
- (void)closeLogFile;
@end


@implementation IRCChannel

@synthesize client;
@synthesize config;

@synthesize mode;
@synthesize topic;
@synthesize storedTopic;
@synthesize isKeyword;
@synthesize isUnread;
@synthesize isNewTalk;
@synthesize isActive;
@synthesize hasOp;
@synthesize namesInit;
@synthesize whoInit;

- (id)init
{
	if (self = [super init]) {
		mode = [IRCChannelMode new];
		members = [NSMutableArray new];
	}
	return self;
}

- (void)dealloc
{
	[config release];
	[mode release];
	[members release];
	[topic release];
	[storedTopic release];
	[super dealloc];
}

#pragma mark -
#pragma mark Init

- (void)setup:(IRCChannelConfig*)seed
{
	config = [seed mutableCopy];
}

- (void)updateConfig:(IRCChannelConfig*)seed
{
	[config release];
	config = [seed mutableCopy];
}

- (void)updateAutoOp:(IRCChannelConfig*)seed
{
	[config.autoOp removeAllObjects];
	[config.autoOp addObjectsFromArray:seed.autoOp];
}

#pragma mark -
#pragma mark Properties

- (NSString*)name
{
	return config.name;
}

- (void)setName:(NSString *)value
{
	config.name = value;
}

- (NSString*)password
{
	return config.password ?: @"";
}

- (BOOL)isChannel
{
	return config.type == CHANNEL_TYPE_CHANNEL;
}

- (BOOL)isTalk
{
	return config.type == CHANNEL_TYPE_TALK;
}

- (NSString*)channelTypeString
{
	switch (config.type) {
		case CHANNEL_TYPE_CHANNEL: return @"channel";
		case CHANNEL_TYPE_TALK: return @"talk";
	}
	return nil;
}

#pragma mark -
#pragma mark Utilities

- (void)terminate
{
	terminating = YES;
	[self closeDialogs];
	[self closeLogFile];
}

- (void)closeDialogs
{
}

- (void)activate
{
	isActive = YES;
	[members removeAllObjects];
	[mode clear];
	hasOp = NO;
	self.topic = nil;
	namesInit = NO;
	whoInit = NO;
	[self reloadMemberList];
}

- (void)deactivate
{
	isActive = NO;
	[members removeAllObjects];
	hasOp = NO;
	[self reloadMemberList];
}

- (BOOL)print:(LogLine*)line
{
	BOOL result = [log print:line];
	
	// write to log file
	
	return result;
}

#pragma mark -
#pragma mark Member List

- (void)sortedInsert:(IRCUser*)item
{
	const int LINEAR_SEARCH_THRESHOLD = 5;
	int left = 0;
	int right = members.count;
	
	while (right - left > LINEAR_SEARCH_THRESHOLD) {
		int i = (left + right) / 2;
		IRCUser* t = [members objectAtIndex:i];
		if ([t compare:item] == NSOrderedAscending) {
			left = i + 1;
		}
		else {
			right = i + 1;
		}
	}
	
	for (int i=left; i<right; ++i) {
		IRCUser* t = [members objectAtIndex:i];
		if ([t compare:item] == NSOrderedDescending) {
			[members insertObject:item atIndex:i];
			return;
		}
	}
	
	[members addObject:item];
}

- (void)addMember:(IRCUser*)user
{
	[self addMember:user reload:YES];
}

- (void)addMember:(IRCUser*)user reload:(BOOL)reload
{
	int n = [self indexOfMember:user.nick];
	if (n >= 0) {
		[[[members objectAtIndex:n] retain] autorelease];
		[members removeObjectAtIndex:n];
	}
	
	[self sortedInsert:user];
	
	if (reload) [self reloadMemberList];
}

- (void)removeMember:(NSString*)nick
{
	[self removeMember:nick reload:YES];
}

- (void)removeMember:(NSString*)nick reload:(BOOL)reload
{
	int n = [self indexOfMember:nick];
	if (n >= 0) {
		[[[members objectAtIndex:n] retain] autorelease];
		[members removeObjectAtIndex:n];
	}

	if (reload) [self reloadMemberList];
}

- (void)renameMember:(NSString*)fromNick to:(NSString*)toNick
{
	int n = [self indexOfMember:fromNick];
	if (n < 0) return;
	
	IRCUser* m = [members objectAtIndex:n];
	[[m retain] autorelease];
	[self removeMember:toNick reload:NO];
	
	m.nick = toNick;
	
	[[[members objectAtIndex:n] retain] autorelease];
	[members removeObjectAtIndex:n];
	
	[self sortedInsert:m];
	
	[self reloadMemberList];
	
	//
	// @@@ update op queue
	//
}

- (void)updateOrAddMember:(IRCUser*)user
{
	int n = [self indexOfMember:user.nick];
	if (n >= 0) {
		[[[members objectAtIndex:n] retain] autorelease];
		[members removeObjectAtIndex:n];
	}
	
	[self sortedInsert:user];
}

- (void)changeMember:(NSString*)nick mode:(char)modeChar value:(BOOL)value
{
	int n = [self indexOfMember:nick];
	if (n < 0) return;
	
	IRCUser* m = [members objectAtIndex:n];
	
	switch (modeChar) {
		case 'q': m.q = value; break;
		case 'a': m.a = value; break;
		case 'o': m.o = value; break;
		case 'h': m.h = value; break;
		case 'v': m.v = value; break;
	}
	
	[[[members objectAtIndex:n] retain] autorelease];
	[members removeObjectAtIndex:n];
	
	[self sortedInsert:m];
	[self reloadMemberList];
}

- (void)clearMembers
{
	[members removeAllObjects];
	[self reloadMemberList];
}

- (int)indexOfMember:(NSString*)nick
{
	NSString* canonicalNick = [nick canonicalName];
	
	int i = 0;
	for (IRCUser* m in members) {
		if ([m.canonicalNick isEqualToString:canonicalNick]) {
			return i;
		}
		++i;
	}
	
	return -1;
}

- (IRCUser*)memberAtIndex:(int)index
{
	return [members objectAtIndex:index];
}

- (IRCUser*)findMember:(NSString*)nick
{
	int n = [self indexOfMember:nick];
	if (n < 0) return nil;
	return [members objectAtIndex:n];
}

- (int)numberOfMembers
{
	return members.count;
}

- (void)reloadMemberList
{
	if (client.world.selected == self) {
		[client.world.memberList reloadData];
	}
}

- (void)closeLogFile
{
}

#pragma mark -
#pragma mark IRCTreeItem

- (BOOL)isClient
{
	return NO;
}

- (IRCClient*)client
{
	return client;
}

- (void)resetState
{
	isKeyword = isUnread = isNewTalk = NO;
}

- (int)numberOfChildren
{
	return 0;
}

- (id)childAtIndex:(int)index
{
	return nil;
}

- (NSString*)label
{
	return config.name;
}

#pragma mark -
#pragma mark NSTableViwe Delegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)sender
{
	return members.count;
}

- (id)tableView:(NSTableView *)sender objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
	return @"";
}

- (void)tableView:(NSTableView *)sender willDisplayCell:(MemberListViewCell*)cell forTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
	cell.member = [members objectAtIndex:row];
}

@end
