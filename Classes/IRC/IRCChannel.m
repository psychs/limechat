// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "IRCChannel.h"
#import "IRCClient.h"
#import "IRCWorld.h"
#import "Preferences.h"
#import "MemberListViewCell.h"
#import "NSStringHelper.h"


@interface IRCChannel (Private)
- (void)closeLogFile;
@end


@implementation IRCChannel

@synthesize client;
@synthesize config;

@synthesize mode;
@synthesize members;
@synthesize topic;
@synthesize storedTopic;
@synthesize isActive;
@synthesize isOp;
@synthesize isModeInit;
@synthesize isNamesInit;
@synthesize isWhoInit;

@synthesize propertyDialog;

- (id)init
{
	self = [super init];
	if (self) {
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
	
	[logFile release];
	[logDate release];
	
	[propertyDialog release];
	[super dealloc];
}

#pragma mark -
#pragma mark Init

- (void)setup:(IRCChannelConfig*)seed
{
	[config autorelease];
	config = [seed mutableCopy];
}

- (void)updateConfig:(IRCChannelConfig*)seed
{
	[config autorelease];
	config = [seed mutableCopy];
}

- (void)updateAutoOp:(IRCChannelConfig*)seed
{
	[config.autoOp removeAllObjects];
	[config.autoOp addObjectsFromArray:seed.autoOp];
}

- (NSMutableDictionary*)dictionaryValue
{
	return [config dictionaryValue];
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

- (void)preferencesChanged
{
	log.maxLines = [Preferences maxLogLines];
	
	if (logFile) {
		if ([Preferences logTranscript]) {
			[logFile reopenIfNeeded];
		}
		else {
			[self closeLogFile];
		}
	}
}

- (void)activate
{
	isActive = YES;
	[members removeAllObjects];
	[mode clear];
	isOp = NO;
	self.topic = nil;
	isModeInit = NO;
	isNamesInit = NO;
	isWhoInit = NO;
	[self reloadMemberList];
}

- (void)deactivate
{
	isActive = NO;
	[members removeAllObjects];
	isOp = NO;
	[self reloadMemberList];
}

- (BOOL)print:(LogLine*)line
{
	BOOL result = [log print:line];
	
	// log
	if (!terminating) {
		if ([Preferences logTranscript]) {
			if (!logFile) {
				logFile = [FileLogger new];
				logFile.client = client;
				logFile.channel = self;
			}
			
			// check date
			NSCalendar* cal = [NSCalendar currentCalendar];
			NSDate* now = [NSDate date];
			NSDateComponents* comp = [cal components:NSDayCalendarUnit|NSMonthCalendarUnit|NSYearCalendarUnit fromDate:now];
			if (logDate) {
				if (![logDate isEqual:comp]) {
					[logDate release];
					logDate = [comp retain];
					[logFile reopenIfNeeded];
				}
			}
			else {
				logDate = [comp retain];
			}
			
			// write line to file
			NSString* nickStr = @"";
			if (line.nick) {
				nickStr = [NSString stringWithFormat:@"%@: ", line.nickInfo];
			}
			NSString* s = [NSString stringWithFormat:@"%@%@%@", line.time, nickStr, line.body];
			[logFile writeLine:s];
		}
	}
	
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
	if ([fromNick isEqualToString:toNick]) return;

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
	if (logFile) {
		[logFile close];
	}
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
