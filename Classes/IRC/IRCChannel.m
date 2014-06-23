// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "IRCChannel.h"
#import "IRCClient.h"
#import "IRCWorld.h"
#import "Preferences.h"
#import "MemberListViewCell.h"
#import "NSStringHelper.h"


@implementation IRCChannel
{
    IRCClient* _client;
    BOOL _terminating;
    FileLogger* _logFile;
    NSDateComponents* _logDate;
}

- (id)init
{
    self = [super init];
    if (self) {
        _mode = [IRCChannelMode new];
        _members = [NSMutableArray new];
    }
    return self;
}

#pragma mark - Init

- (void)setup:(IRCChannelConfig*)seed
{
    _config = seed;
}

- (void)updateConfig:(IRCChannelConfig*)seed
{
    _config = [seed mutableCopy];
}

- (void)updateAutoOp:(IRCChannelConfig*)seed
{
    [_config.autoOp removeAllObjects];
    [_config.autoOp addObjectsFromArray:seed.autoOp];
}

- (NSMutableDictionary*)dictionaryValue
{
    return [_config dictionaryValueSavingToKeychain:YES];
}

#pragma mark - Properties

- (NSString*)name
{
    return _config.name;
}

- (void)setName:(NSString *)value
{
    _config.name = value;
}

- (NSString*)password
{
    return _config.password ?: @"";
}

- (BOOL)isChannel
{
    return _config.type == CHANNEL_TYPE_CHANNEL;
}

- (BOOL)isTalk
{
    return _config.type == CHANNEL_TYPE_TALK;
}

- (NSString*)channelTypeString
{
    switch (_config.type) {
        case CHANNEL_TYPE_CHANNEL: return @"channel";
        case CHANNEL_TYPE_TALK: return @"talk";
    }
    return nil;
}

#pragma mark - Utilities

- (void)terminate
{
    _terminating = YES;
    [self closeDialogs];
    [self closeLogFile];
}

- (void)closeDialogs
{
}

- (void)preferencesChanged
{
    self.log.maxLines = [Preferences maxLogLines];

    if (_logFile) {
        if ([Preferences logTranscript]) {
            [_logFile reopenIfNeeded];
        }
        else {
            [self closeLogFile];
        }
    }
}

- (void)activate
{
    self.isActive = YES;
    [_members removeAllObjects];
    [_mode clear];
    _isOp = NO;
    self.topic = nil;
    _isModeInit = NO;
    _isNamesInit = NO;
    _isWhoInit = NO;
    [self reloadMemberList];
}

- (void)deactivate
{
    self.isActive = NO;
    [_members removeAllObjects];
    _isOp = NO;
    [self reloadMemberList];
}

- (BOOL)print:(LogLine*)line
{
    BOOL result = [self.log print:line];

    // log
    if (!_terminating) {
        if ([Preferences logTranscript]) {
            if (!_logFile) {
                _logFile = [FileLogger new];
                _logFile.client = self.client;
                _logFile.channel = self;
            }

            // check date
            NSCalendar* cal = [NSCalendar currentCalendar];
            NSDate* now = [NSDate date];
            NSDateComponents* comp = [cal components:NSDayCalendarUnit|NSMonthCalendarUnit|NSYearCalendarUnit fromDate:now];
            if (_logDate) {
                if (![_logDate isEqual:comp]) {
                    _logDate = comp;
                    [_logFile reopenIfNeeded];
                }
            }
            else {
                _logDate = comp;
            }

            // write line to file
            NSString* nickStr = @"";
            if (line.nick) {
                nickStr = [NSString stringWithFormat:@"%@: ", line.nickInfo];
            }
            NSString* s = [NSString stringWithFormat:@"%@%@%@", line.time, nickStr, line.body];
            [_logFile writeLine:s];
        }
    }

    return result;
}

#pragma mark - Member List

- (void)sortedInsert:(IRCUser*)item
{
    const int LINEAR_SEARCH_THRESHOLD = 5;
    int left = 0;
    int right = _members.count;

    while (right - left > LINEAR_SEARCH_THRESHOLD) {
        int i = (left + right) / 2;
        IRCUser* t = [_members objectAtIndex:i];
        if ([t compare:item] == NSOrderedAscending) {
            left = i + 1;
        }
        else {
            right = i + 1;
        }
    }

    for (int i=left; i<right; ++i) {
        IRCUser* t = [_members objectAtIndex:i];
        if ([t compare:item] == NSOrderedDescending) {
            [_members insertObject:item atIndex:i];
            return;
        }
    }

    [_members addObject:item];
}

- (void)addMember:(IRCUser*)user
{
    [self addMember:user reload:YES];
}

- (void)addMember:(IRCUser*)user reload:(BOOL)reload
{
    int n = [self indexOfMember:user.nick];
    if (n >= 0) {
        [_members objectAtIndex:n];
        [_members removeObjectAtIndex:n];
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
        [_members objectAtIndex:n];
        [_members removeObjectAtIndex:n];
    }

    if (reload) [self reloadMemberList];
}

- (void)renameMember:(NSString*)fromNick to:(NSString*)toNick
{
    if ([fromNick isEqualToString:toNick]) return;

    int n = [self indexOfMember:fromNick];
    if (n < 0) return;

    IRCUser* m = [_members objectAtIndex:n];
    [_members removeObjectAtIndex:n];

    m.nick = toNick;

    if (![fromNick isEqualNoCase:toNick]) {
        [self removeMember:toNick reload:NO];
    }
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
        [_members objectAtIndex:n];
        [_members removeObjectAtIndex:n];
    }

    [self sortedInsert:user];
}

- (void)changeMember:(NSString*)nick mode:(char)modeChar value:(BOOL)value
{
    int n = [self indexOfMember:nick];
    if (n < 0) return;

    IRCUser* m = [_members objectAtIndex:n];

    switch (modeChar) {
        case 'q': m.q = value; break;
        case 'a': m.a = value; break;
        case 'o': m.o = value; break;
        case 'h': m.h = value; break;
        case 'v': m.v = value; break;
    }

    [_members objectAtIndex:n];
    [_members removeObjectAtIndex:n];

    [self sortedInsert:m];
    [self reloadMemberList];
}

- (void)clearMembers
{
    [_members removeAllObjects];
    [self reloadMemberList];
}

- (int)indexOfMember:(NSString*)nick
{
    NSString* canonicalNick = [nick canonicalName];

    int i = 0;
    for (IRCUser* m in _members) {
        if ([m.canonicalNick isEqualToString:canonicalNick]) {
            return i;
        }
        ++i;
    }

    return -1;
}

- (IRCUser*)memberAtIndex:(int)index
{
    return [_members objectAtIndex:index];
}

- (IRCUser*)findMember:(NSString*)nick
{
    int n = [self indexOfMember:nick];
    if (n < 0) return nil;
    return [_members objectAtIndex:n];
}

- (int)numberOfMembers
{
    return _members.count;
}

- (void)reloadMemberList
{
    if (_client.world.selected == self) {
        [_client.world.memberList reloadData];
    }
}

- (void)closeLogFile
{
    if (_logFile) {
        [_logFile close];
    }
}

#pragma mark - IRCTreeItem

- (BOOL)isClient
{
    return NO;
}

- (void)setClient:(IRCClient *)value
{
    _client = value;
}

- (IRCClient*)client
{
    return _client;
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
    return _config.name;
}

#pragma mark - NSTableViwe Delegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)sender
{
    return _members.count;
}

- (id)tableView:(NSTableView *)sender objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
    return @"";
}

- (void)tableView:(NSTableView *)sender willDisplayCell:(MemberListViewCell*)cell forTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
    cell.member = [_members objectAtIndex:row];
}

@end
