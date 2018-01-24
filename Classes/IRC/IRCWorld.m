// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "IRCWorld.h"
#import "IRCClient.h"
#import "IRCChannel.h"
#import "IRCClientConfig.h"
#import "IRC.h"
#import "Preferences.h"
#import "NSStringHelper.h"


#define AUTO_CONNECT_DELAY              1
#define RECONNECT_AFTER_WAKE_UP_DELAY   8

#define TREE_DRAG_ITEM_TYPE             @"tree"
#define TREE_DRAG_ITEM_TYPES            [NSArray arrayWithObject:TREE_DRAG_ITEM_TYPE]


@implementation IRCWorld
{
    IconController* _icon;
    LogController* _dummyLog;
    IRCWorldConfig* _config;

    NSMenu* _serverMenu;
    NSMenu* _channelMenu;

    int _itemId;
    BOOL _reloadingTree;
    IRCTreeItem* _selected;

    int _previousSelectedClientId;
    int _previousSelectedChannelId;
}

- (id)init
{
    self = [super init];
    if (self) {
        _icon = [IconController new];
        _clients = [NSMutableArray new];
    }
    return self;
}

#pragma mark - Init

- (void)setup:(IRCWorldConfig*)seed
{
    _consoleLog = [self createLogWithClient:nil channel:nil console:YES];
    _consoleBase.contentView = _consoleLog.view;
    [_consoleLog notifyDidBecomeVisible];

    _dummyLog = [self createLogWithClient:nil channel:nil console:YES];
    _logBase.contentView = _dummyLog.view;
    [_dummyLog notifyDidBecomeVisible];

    _config = [seed mutableCopy];
    for (IRCClientConfig* e in _config.clients) {
        [self createClient:e reload:YES];
    }
    [_config.clients removeAllObjects];

    [self changeInputTextTheme];
    [self changeTreeTheme];
    [self changeMemberListTheme];
}

- (void)setupTree
{
    [_tree setTarget:self];
    [_tree setDoubleAction:@selector(outlineViewDoubleClicked:)];
    [_tree registerForDraggedTypes:TREE_DRAG_ITEM_TYPES];

    IRCClient* client = nil;;
    for (IRCClient* e in _clients) {
        if (e.config.autoConnect) {
            client = e;
            break;
        }
    }

    if (client) {
        [_tree expandItem:client];
        int n = [_tree rowForItem:client];
        if (client.channels.count) ++n;
        [_tree selectItemAtIndex:n];
    }
    else if (_clients.count > 0) {
        [_tree selectItemAtIndex:0];
    }

    [self reflectTreeSelection];
}

- (void)save
{
    [Preferences saveWorld:[self dictionaryValue]];
    [Preferences sync];
}

- (NSMutableDictionary*)dictionaryValue
{
    NSMutableDictionary* dic = [_config dictionaryValueSavingToKeychain:YES includingChildren:NO];

    NSMutableArray* ary = [NSMutableArray array];
    for (IRCClient* u in _clients) {
        [ary addObject:[u dictionaryValue]];
    }

    [dic setObject:ary forKey:@"clients"];
    return dic;
}

- (void)setServerMenuItem:(NSMenuItem*)item
{
    if (_serverMenu) return;

    _serverMenu = [[item submenu] copy];
}

- (void)setChannelMenuItem:(NSMenuItem*)item
{
    if (_channelMenu) return;

    _channelMenu = [[item submenu] copy];
}

#pragma mark - Properties

- (IRCClient*)selectedClient
{
    if (!_selected) return nil;
    return [_selected client];
}

- (IRCChannel*)selectedChannel
{
    if (!_selected) return nil;
    if ([_selected isClient]) return nil;
    return (IRCChannel*)_selected;
}

#pragma mark - Utilities

- (void)onTimer
{
    for (IRCClient* c in _clients) {
        [c onTimer];
    }
}

- (void)autoConnect:(BOOL)afterWakeUp
{
    int delay = 0;
    if (afterWakeUp) delay += RECONNECT_AFTER_WAKE_UP_DELAY;

    for (IRCClient* c in _clients) {
        if (c.config.autoConnect) {
            [c autoConnect:delay];
            delay += AUTO_CONNECT_DELAY;
        }
    }
}

- (void)terminate
{
    for (IRCClient* c in _clients) {
        [c terminate];
    }
}

- (void)prepareForSleep
{
    for (IRCClient* c in _clients) {
        [c disconnect];
    }
}

- (void)focusInputText
{
    [_text focus];
}

- (BOOL)inputText:(NSString*)s command:(NSString*)command
{
    if (!_selected) return NO;
    return [[_selected client] inputText:s command:command];
}

- (void)markAllAsRead
{
    for (IRCClient* u in _clients) {
        u.isUnread = NO;
        for (IRCChannel* c in u.channels) {
            c.isUnread = NO;
        }
    }
    [self reloadTree];
}

- (void)markAllScrollbacks
{
    for (IRCClient* u in _clients) {
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

    for (IRCClient* u in _clients) {
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

    [_icon setHighlight:highlight newTalk:newTalk];
}

- (void)reloadTree
{
    if (_reloadingTree) {
        [_tree setNeedsDisplay];
        return;
    }

    _reloadingTree = YES;
    [_tree reloadData];
    _reloadingTree = NO;
}

- (void)expandClient:(IRCClient*)client
{
    [_tree expandItem:client];
}

- (void)adjustSelection
{
    NSInteger row = [_tree selectedRow];
    if (0 <= row && _selected && _selected != [_tree itemAtRow:row]) {
        [_tree selectItemAtIndex:[_tree rowForItem:_selected]];
        [self reloadTree];
    }
}

- (void)storePreviousSelection
{
    if (!_selected) {
        _previousSelectedClientId = 0;
        _previousSelectedChannelId = 0;
    }
    else if (_selected.isClient) {
        _previousSelectedClientId = _selected.uid;
        _previousSelectedChannelId = 0;
    }
    else {
        _previousSelectedClientId = _selected.client.uid;
        _previousSelectedChannelId = _selected.uid;
    }
}

- (void)selectPreviousItem
{
    if (!_previousSelectedClientId && !_previousSelectedClientId) return;

    int uid = _previousSelectedClientId;
    int cid = _previousSelectedChannelId;

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
    _consoleLog.maxLines = [Preferences maxLogLines];

    for (IRCClient* c in _clients) {
        [c preferencesChanged];
    }
}

#pragma mark - User Notification

- (void)sendUserNotification:(UserNotificationType)type title:(NSString*)title desc:(NSString*)desc context:(id)context
{
    if ([Preferences stopNotificationsOnActive] && [NSApp isActive]) return;
    if (![Preferences userNotificationEnabledForEvent:type]) return;

    [_notifier notify:type title:title desc:desc context:context];
}

- (void)notificationControllerDidActivateNotification:(id)context actionButtonClicked:(BOOL)actionButtonClicked
{
    [_window makeKeyAndOrderFront:nil];
	[NSApp activateIgnoringOtherApps:YES];

    LOG(@"Notification clicked: %@", context);

	if ([context isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dic = (NSDictionary*)context;
        if ([dic objectForKey:USER_NOTIFICATION_DCC_KEY]) {
            [self.dcc show:YES];
        }
        else {
            NSNumber* clientId = [dic objectForKey:USER_NOTIFICATION_CLIENT_ID_KEY];
            NSNumber* channelId = [dic objectForKey:USER_NOTIFICATION_CHANNEL_ID_KEY];
            NSString* invitedChannelName = [dic objectForKey:USER_NOTIFICATION_INVITED_CHANNEL_NAME_KEY];

            if (invitedChannelName && clientId) {
                IRCClient* u = [self findClientById:clientId.intValue];
                if (u) {
                    [u sendJoinAndSelect:invitedChannelName];
                }
            }
            else if (clientId && channelId) {
                IRCClient* u = [self findClientById:clientId.intValue];
                IRCChannel* c = [self findChannelByClientId:clientId.intValue channelId:channelId.intValue];
                if (c) {
                    [self select:c];
                }
                else if (u) {
                    [self select:u];
                }
            }
            else if (clientId) {
                IRCClient* u = [self findClientById:clientId.intValue];
                if (u) {
                    [self select:u];
                }
            }
        }
	}
}

#pragma mark - Window Title

- (void)updateTitle
{
    if (!_selected) {
        [_window setTitle:@"LimeChat"];
        return;
    }

    IRCTreeItem* sel = _selected;
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
        [_window setTitle:title];
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
        [_window setTitle:title];
    }
}

- (void)updateClientTitle:(IRCClient*)client
{
    if (!client || !_selected) return;
    if ([_selected client] == client) {
        [self updateTitle];
    }
}

- (void)updateChannelTitle:(IRCChannel*)channel
{
    if (!channel || !_selected) return;
    if (_selected == channel) {
        [self updateTitle];
    }
}

#pragma mark - Tree Items

- (IRCClient*)findClient:(NSString*)name
{
    for (IRCClient* u in _clients) {
        if ([u.name isEqualToString:name]) {
            return u;
        }
    }
    return nil;
}

- (IRCClient*)findClientById:(int)uid
{
    for (IRCClient* u in _clients) {
        if (u.uid == uid) {
            return u;
        }
    }
    return nil;
}

- (IRCChannel*)findChannelByClientId:(int)uid channelId:(int)cid
{
    for (IRCClient* u in _clients) {
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
    if (_selected == item) return;

    [self storePreviousSelection];
    [self focusInputText];

    if (!item) {
        self.selected = nil;

        _logBase.contentView = _dummyLog.view;
        [_dummyLog notifyDidBecomeVisible];

        _memberList.dataSource = nil;
        [_memberList reloadData];
        _tree.menu = _treeMenu;
        return;
    }

    BOOL isClient = [item isClient];
    IRCClient* client = (IRCClient*)[item client];

    if (!isClient) [_tree expandItem:client];

    int i = [_tree rowForItem:item];
    if (i < 0) return;
    [_tree selectItemAtIndex:i];

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
    if (0 <= n && n < _clients.count) {
        IRCClient* c = [_clients objectAtIndex:n];
        IRCChannel* e = c.lastSelectedChannel;
        if (e) {
            [self select:e];
        }
        else {
            [self select:c];
        }
    }
}

#pragma mark - Theme

- (void)reloadTheme
{
    _viewTheme.name = [Preferences themeName];

    NSMutableArray* logs = [NSMutableArray array];
    [logs addObject:_consoleLog];
    for (IRCClient* u in _clients) {
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
    OtherTheme* theme = _viewTheme.other;

    [_fieldEditor setInsertionPointColor:theme.inputTextColor];
    [_text setTextColor:theme.inputTextColor];
    [_text setBackgroundColor:theme.inputTextBgColor];

    NSFont* inputFont = nil;
    if ([Preferences themeOverrideInputFont]) {
        inputFont = [NSFont fontWithName:[Preferences themeInputFontName] size:[Preferences themeInputFontSize]];
    }
    if (!inputFont) {
        inputFont = theme.inputTextFont;
    }
    [_chatBox setInputTextFont:inputFont];

    if ([_window firstResponder] == [_window fieldEditor:NO forObject:_text]) {
        [_window makeFirstResponder:_dummyLog.view];
        [_window performSelector:@selector(makeFirstResponder:) withObject:_text afterDelay:0.001];
    }
}

- (void)changeTreeTheme
{
    OtherTheme* theme = _viewTheme.other;

    [_tree setFont:theme.treeFont];
    [_tree themeChanged];
    [_tree setNeedsDisplay];
}

- (void)changeMemberListTheme
{
    OtherTheme* theme = _viewTheme.other;

    [_memberList setFont:theme.memberListFont];
    [[[[_memberList tableColumns] objectAtIndex:0] dataCell] themeChanged];
    [_memberList themeChanged];
    [_memberList setNeedsDisplay];
}

- (void)changeTextSize:(BOOL)bigger
{
    [_consoleLog changeTextSize:bigger];

    for (IRCClient* u in _clients) {
        [u.log changeTextSize:bigger];
        for (IRCChannel* c in u.channels) {
            [c.log changeTextSize:bigger];
        }
    }
}

#pragma mark - Factory

- (IRCClient*)createClient:(IRCClientConfig*)seed reload:(BOOL)reload
{
    IRCClient* c = [IRCClient new];
    c.uid = ++_itemId;
    c.world = self;
    c.log = [self createLogWithClient:c channel:nil console:NO];
    [c setup:seed];

    for (IRCChannelConfig* e in seed.channels) {
        [self createChannel:e client:c reload:NO adjust:NO];
    }

    [_clients addObject:c];

    if (reload) [self reloadTree];

    return c;
}

- (IRCChannel*)createChannel:(IRCChannelConfig*)seed client:(IRCClient*)client reload:(BOOL)reload adjust:(BOOL)adjust
{
    IRCChannel* c = [client findChannel:seed.name];
    if (c) return c;

    c = [IRCChannel new];
    c.uid = ++_itemId;
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
    IRCChannelConfig* seed = [IRCChannelConfig new];
    seed.name = nick;
    seed.type = CHANNEL_TYPE_TALK;
    IRCChannel* c = [self createChannel:seed client:client reload:YES adjust:YES];

    if (client.isLoggedIn) {
        [c activate];

        IRCUser* m;
        m = [IRCUser new];
        m.isupport = client.isupport;
        m.nick = client.myNick;
        [c addMember:m];

        m = [IRCUser new];
        m.isupport = client.isupport;
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
        i = [_clients indexOfObjectIdenticalTo:target];
        int n = i + 1;
        if (0 <= n && n < _clients.count) {
            sel = [_clients objectAtIndex:n];
        }
        i = [_tree rowForItem:target];
    }
    else {
        i = [_tree rowForItem:target];
        int n = i + 1;
        if (0 <= n && n < [_tree numberOfRows]) {
            sel = [_tree itemAtRow:n];
        }
        if (sel && sel.isClient) {
            // we don't want to change clients when closing a channel
            n = i - 1;
            if (0 <= n && n < [_tree numberOfRows]) {
                sel = [_tree itemAtRow:n];
            }
        }
    }

    if (sel) {
        [self select:sel];
    }
    else {
        int n = i - 1;
        if (0 <= n && n < [_tree numberOfRows]) {
            sel = [_tree itemAtRow:n];
        }
        [self select:sel];
    }

    if (target.isClient) {
        IRCClient* u = (IRCClient*)target;
        for (IRCChannel* c in u.channels) {
            [c closeDialogs];
        }
        [_clients removeObjectIdenticalTo:target];
    }
    else {
        [target.client.channels removeObjectIdenticalTo:target];
    }

    [self reloadTree];

    if (_selected) {
        [_tree selectItemAtIndex:[_tree rowForItem:sel]];
    }
}

- (void)destroyClient:(IRCClient*)u
{
    [u terminate];
    [u disconnect];

    [u.config deletePasswordsFromKeychain];

    if (_selected && _selected.client == u) {
        [self selectOtherAndDestroy:u];
    }
    else {
        [_clients removeObjectIdenticalTo:u];
        [self reloadTree];
        [self adjustSelection];
    }
}

- (void)destroyChannel:(IRCChannel*)c
{
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

    [c.config deletePasswordsFromKeychain];

    if (_selected == c) {
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
    LogController* c = [LogController new];
    c.menu = console ? _consoleMenu : _logMenu;
    c.urlMenu = _urlMenu;
    c.addrMenu = _addrMenu;
    c.chanMenu = _chanMenu;
    c.memberMenu = _memberMenu;
    c.world = self;
    c.client = client;
    c.channel = channel;
    c.maxLines = [Preferences maxLogLines];
    c.theme = _viewTheme;
    c.console = console;
    c.initialBackgroundColor = [_viewTheme.other inputTextBgColor];
    [c setUp];

    [c.view setHostWindow:_window];
    if (_consoleLog) {
        [c.view setTextSizeMultiplier:_consoleLog.view.textSizeMultiplier];
    }

    return c;
}

#pragma mark - Log Delegate

- (void)logKeyDown:(NSEvent*)e
{
    [_window makeFirstResponder:_text];
    [self focusInputText];

    switch (e.keyCode) {
        case KEY_RETURN:
        case KEY_ENTER:
            return;
    }

    [_window sendEvent:e];
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

#pragma mark - NSOutlineView Delegate

- (void)outlineViewDoubleClicked:(id)sender
{
    if (!_selected) return;

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
    if (!item) return _clients.count;
    return [item numberOfChildren];
}

- (BOOL)outlineView:(NSOutlineView *)sender isItemExpandable:(id)item
{
    return [item numberOfChildren] > 0;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(IRCTreeItem*)item
{
    if (!item) return [_clients objectAtIndex:index];
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
    [self reflectTreeSelection];
}

- (void)reflectTreeSelection
{
    id nextItem = [_tree itemAtRow:[_tree selectedRow]];

    [_text focus];

    self.selected = nextItem;

    if (!_selected) {
        _logBase.contentView = _dummyLog.view;
        [_dummyLog notifyDidBecomeVisible];

        _tree.menu = _treeMenu;
        _memberList.dataSource = nil;
        _memberList.delegate = nil;
        [_memberList reloadData];
        return;
    }

    [_selected resetState];

    LogController* log = [_selected log];
    _logBase.contentView = [log view];
    [log notifyDidBecomeVisible];

    if ([_selected isClient]) {
        _tree.menu = _serverMenu;
        _memberList.dataSource = nil;
        _memberList.delegate = nil;
        [_memberList reloadData];
    }
    else {
        _tree.menu = _channelMenu;
        _memberList.dataSource = _selected;
        _memberList.delegate = _selected;
        [_memberList reloadData];
    }

    [_memberList deselectAll:nil];
    [_memberList scrollRowToVisible:0];
    [_selected.log.view clearSelection];

    [self updateTitle];
    [self reloadTree];
    [self updateIcon];
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    OtherTheme* theme = _viewTheme.other;
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
        if (i == [_tree itemAtRow:[_tree selectedRow]]) {
            if ([NSApp isActive]) {
                color = theme.treeSelActiveColor;
            }
            else {
                color = theme.treeActiveColor;
            }
        }
        else {
            color = theme.treeActiveColor;
        }
    }
    else {
        if (i == [_tree itemAtRow:[_tree selectedRow]]) {
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
        NSMutableArray* low = [[ary subarrayWithRange:NSMakeRange(0, index)] mutableCopy];
        NSMutableArray* high = [[ary subarrayWithRange:NSMakeRange(index, ary.count - index)] mutableCopy];
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

        NSMutableArray* ary = _clients;
        NSMutableArray* low = [[ary subarrayWithRange:NSMakeRange(0, index)] mutableCopy];
        NSMutableArray* high = [[ary subarrayWithRange:NSMakeRange(index, ary.count - index)] mutableCopy];
        [low removeObjectIdenticalTo:i];
        [high removeObjectIdenticalTo:i];

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
        NSMutableArray* low = [[ary subarrayWithRange:NSMakeRange(0, index)] mutableCopy];
        NSMutableArray* high = [[ary subarrayWithRange:NSMakeRange(index, ary.count - index)] mutableCopy];
        [low removeObjectIdenticalTo:i];
        [high removeObjectIdenticalTo:i];

        [ary removeAllObjects];
        [ary addObjectsFromArray:low];
        [ary addObject:i];
        [ary addObjectsFromArray:high];
        [self reloadTree];
        [self save];
    }

    int n = [_tree rowForItem:_selected];
    if (n >= 0) {
        [_tree selectItemAtIndex:n];
    }

    return YES;
}

#pragma mark - memberListView Delegate

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
            [_dcc addSenderWithUID:u.uid nick:m.nick fileName:s autoOpen:YES];
        }
    }
}

@end
