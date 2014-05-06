// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "ServerDialog.h"
#import "NSWindowHelper.h"
#import "NSLocaleHelper.h"
#import "IRCChannelConfig.h"
#import "IgnoreItem.h"


#define IGNORE_TAB_INDEX    3

#define TABLE_ROW_TYPE      @"row"
#define TABLE_ROW_TYPES     [NSArray arrayWithObject:TABLE_ROW_TYPE]


@implementation ServerDialog
{
    ChannelDialog* _channelSheet;
    IgnoreItemSheet* _ignoreSheet;
}

- (id)init
{
    self = [super init];
    if (self) {
        [NSBundle loadNibNamed:@"ServerDialog" owner:self];

        NSArray* servers = [[self class] availableServers];
        for (NSString* s in servers) {
            [_hostCombo addItemWithObjectValue:s];
        }
    }
    return self;
}

- (void)startWithIgnoreTab:(BOOL)ignoreTab
{
    if (_uid < 0) {
        [self.window setTitle:@"New Server"];
    }

    [_channelTable setTarget:self];
    [_channelTable setDoubleAction:@selector(tableViewDoubleClicked:)];
    [_channelTable registerForDraggedTypes:TABLE_ROW_TYPES];

    [_ignoreTable setTarget:self];
    [_ignoreTable setDoubleAction:@selector(tableViewDoubleClicked:)];
    [_ignoreTable registerForDraggedTypes:TABLE_ROW_TYPES];

    [self load];
    [self updateConnectionPage];
    [self updateChannelsPage];
    [self updateIgnoresPage];
    [self encodingChanged:nil];
    [self proxyChanged:nil];
    [self reloadChannelTable];
    [self reloadIgnoreTable];

    if (ignoreTab) {
        [_tab selectTabViewItem:[_tab tabViewItemAtIndex:IGNORE_TAB_INDEX]];
    }

    [self show];
}

- (void)show
{
    if (![self.window isVisible]) {
        [self.window centerOfWindow:_parentWindow];
    }
    [self.window makeKeyAndOrderFront:nil];
}

- (void)close
{
    _delegate = nil;
    [self.window close];
}

- (void)load
{
    _nameText.stringValue = _config.name;
    _autoConnectCheck.state = _config.autoConnect;

    _hostCombo.stringValue = _config.host;
    _sslCheck.state = _config.useSSL;
    _portText.intValue = _config.port;

    _nickText.stringValue = _config.nick;
    _passwordText.stringValue = _config.password;
    _usernameText.stringValue = _config.username;
    _realNameText.stringValue = _config.realName;
    _nickPasswordText.stringValue = _config.nickPassword;
    _saslCheck.state = _config.useSASL;
    if (_config.altNicks.count) {
        _altNicksText.stringValue = [_config.altNicks componentsJoinedByString:@" "];
    }
    else {
        _altNicksText.stringValue = @"";
    }

    _leavingCommentText.stringValue = _config.leavingComment;
    _userInfoText.stringValue = _config.userInfo;

    [_encodingCombo selectItemWithTag:_config.encoding];
    [_fallbackEncodingCombo selectItemWithTag:_config.fallbackEncoding];

    [_proxyCombo selectItemWithTag:_config.proxyType];
    _proxyHostText.stringValue = _config.proxyHost;
    _proxyPortText.intValue = _config.proxyPort;
    _proxyUserText.stringValue = _config.proxyUser;
    _proxyPasswordText.stringValue = _config.proxyPassword;

    _loginCommandsText.string = [_config.loginCommands componentsJoinedByString:@"\n"];
    _invisibleCheck.state = _config.invisibleMode;
}

- (void)save
{
    _config.name = _nameText.stringValue;
    _config.autoConnect = _autoConnectCheck.state;

    _config.host = _hostCombo.stringValue;
    _config.useSSL = _sslCheck.state;
    _config.port = _portText.intValue;

    _config.nick = _nickText.stringValue;
    _config.password = _passwordText.stringValue;
    _config.username = _usernameText.stringValue;
    _config.realName = _realNameText.stringValue;
    _config.nickPassword = _nickPasswordText.stringValue;
    if (_config.nickPassword.length > 0) {
        _config.useSASL = _saslCheck.state;
    }
    else {
        _config.useSASL = NO;
    }

    NSArray* nicks = [_altNicksText.stringValue componentsSeparatedByString:@" "];
    [_config.altNicks removeAllObjects];
    for (NSString* s in nicks) {
        if (s.length) {
            [_config.altNicks addObject:s];
        }
    }

    _config.leavingComment = _leavingCommentText.stringValue;
    _config.userInfo = _userInfoText.stringValue;

    _config.encoding = _encodingCombo.selectedTag;
    _config.fallbackEncoding = _fallbackEncodingCombo.selectedTag;

    _config.proxyType = _proxyCombo.selectedTag;
    _config.proxyHost = _proxyHostText.stringValue;
    _config.proxyPort = _proxyPortText.intValue;
    _config.proxyUser = _proxyUserText.stringValue;
    _config.proxyPassword = _proxyPasswordText.stringValue;

    NSArray* commands = [_loginCommandsText.string componentsSeparatedByString:@"\n"];
    [_config.loginCommands removeAllObjects];
    for (NSString* s in commands) {
        if (s.length) {
            [_config.loginCommands addObject:s];
        }
    }

    _config.invisibleMode = _invisibleCheck.state;
}

- (void)updateConnectionPage
{
    NSString* name = [_nameText stringValue];
    NSString* host = [_hostCombo stringValue];
    int port = [_portText intValue];
    NSString* nick = [_nickText stringValue];
    NSString* nickPassword = [_nickPasswordText stringValue];

    BOOL enabled = name.length && host.length && ![host isEqualToString:@"-"] && port > 0 && nick.length;
    [_okButton setEnabled:enabled];

    BOOL saslEnabled = nickPassword.length > 0;
    [_saslCheck setEnabled:saslEnabled];
}

- (void)updateChannelsPage
{
    NSInteger i = [_channelTable selectedRow];
    BOOL enabled = (i >= 0);
    [_editChannelButton setEnabled:enabled];
    [_deleteChannelButton setEnabled:enabled];
}

- (void)reloadChannelTable
{
    [_channelTable reloadData];
}

- (void)updateIgnoresPage
{
    NSInteger i = [_ignoreTable selectedRow];
    BOOL enabled = (i >= 0);
    [_editIgnoreButton setEnabled:enabled];
    [_deleteIgnoreButton setEnabled:enabled];
}

- (void)reloadIgnoreTable
{
    [_ignoreTable reloadData];
}

#pragma mark - Actions

- (void)ok:(id)sender
{
    [self save];

    // remove invalid ignores
    NSMutableArray* ignores = _config.ignores;
    for (int i=ignores.count-1; i>=0; --i) {
        IgnoreItem* g = [ignores objectAtIndex:i];
        if (!g.isValid) {
            [ignores removeObjectAtIndex:i];
        }
    }

    if ([_delegate respondsToSelector:@selector(serverDialogOnOK:)]) {
        [_delegate serverDialogOnOK:self];
    }

    [self.window close];
}

- (void)cancel:(id)sender
{
    [self.window close];
}

- (void)controlTextDidChange:(NSNotification*)note
{
    [self updateConnectionPage];
}

- (void)hostComboChanged:(id)sender
{
    [self updateConnectionPage];
}

- (void)encodingChanged:(id)sender
{
    int tag = [_encodingCombo selectedTag];
    [_fallbackEncodingCombo setEnabled:(tag == NSUTF8StringEncoding)];
}

- (void)proxyChanged:(id)sender
{
    int tag = [_proxyCombo selectedTag];
    BOOL enabled = (tag == PROXY_SOCKS4 || tag == PROXY_SOCKS5);
    [_proxyHostText setEnabled:enabled];
    [_proxyPortText setEnabled:enabled];
    [_proxyUserText setEnabled:enabled];
    [_proxyPasswordText setEnabled:enabled];
    //[sslCheck setEnabled:tag == PROXY_NONE];
}

#pragma mark - Channel Actions

- (void)addChannel:(id)sender
{
    NSInteger sel = [_channelTable selectedRow];
    IRCChannelConfig* conf;
    if (sel < 0) {
        conf = [IRCChannelConfig new];
    }
    else {
        IRCChannelConfig* c = [_config.channels objectAtIndex:sel];
        conf = [c mutableCopy];
        conf.name = @"";
    }

    _channelSheet = [ChannelDialog new];
    _channelSheet.delegate = self;
    _channelSheet.parentWindow = self.window;
    _channelSheet.config = conf;
    _channelSheet.uid = 1;
    _channelSheet.cid = -1;
    [_channelSheet startSheet];
}

- (void)editChannel:(id)sender
{
    NSInteger sel = [_channelTable selectedRow];
    if (sel < 0) return;
    IRCChannelConfig* c = [[_config.channels objectAtIndex:sel] mutableCopy];

    _channelSheet = [ChannelDialog new];
    _channelSheet.delegate = self;
    _channelSheet.parentWindow = self.window;
    _channelSheet.config = c;
    _channelSheet.uid = 1;
    _channelSheet.cid = 1;
    [_channelSheet startSheet];
}

- (void)channelDialogOnOK:(ChannelDialog*)sender
{
    IRCChannelConfig* conf = sender.config;
    NSString* name = conf.name;

    int n = -1;
    int i = 0;
    for (IRCChannelConfig* c in _config.channels) {
        if ([c.name isEqualToString:name]) {
            n = i;
            break;
        }
        ++i;
    }

    if (n < 0) {
        [_config.channels addObject:conf];
    }
    else {
        [_config.channels replaceObjectAtIndex:n withObject:conf];
    }

    [self reloadChannelTable];
}

- (void)channelDialogWillClose:(ChannelDialog*)sender
{
    _channelSheet = nil;
}

- (void)deleteChannel:(id)sender
{
    NSInteger sel = [_channelTable selectedRow];
    if (sel < 0) return;

    [_config.channels removeObjectAtIndex:sel];

    int count = _config.channels.count;
    if (count) {
        if (count <= sel) {
            [_channelTable selectItemAtIndex:count - 1];
        }
        else {
            [_channelTable selectItemAtIndex:sel];
        }
    }

    [self reloadChannelTable];
}

#pragma mark - Ignore Actions

- (void)addIgnore:(id)sender
{
    _ignoreSheet = [IgnoreItemSheet new];
    _ignoreSheet.delegate = self;
    _ignoreSheet.parentWindow = self.window;
    _ignoreSheet.ignore = [IgnoreItem new];
    _ignoreSheet.newItem = YES;
    [_ignoreSheet start];
}

- (void)editIgnore:(id)sender
{
    NSInteger sel = [_ignoreTable selectedRow];
    if (sel < 0) return;

    _ignoreSheet = [IgnoreItemSheet new];
    _ignoreSheet.delegate = self;
    _ignoreSheet.parentWindow = self.window;
    _ignoreSheet.ignore = [_config.ignores objectAtIndex:sel];
    [_ignoreSheet start];
}

- (void)deleteIgnore:(id)sender
{
    NSInteger sel = [_ignoreTable selectedRow];
    if (sel < 0) return;

    [_config.ignores removeObjectAtIndex:sel];

    int count = _config.ignores.count;
    if (count) {
        if (count <= sel) {
            [_ignoreTable selectItemAtIndex:count - 1];
        }
        else {
            [_ignoreTable selectItemAtIndex:sel];
        }
    }

    [self reloadIgnoreTable];
}

- (void)ignoreItemSheetOnOK:(IgnoreItemSheet*)sender
{
    if (sender.newItem) {
        [_config.ignores addObject:sender.ignore];
    }

    [self reloadIgnoreTable];
}

- (void)ignoreItemSheetWillClose:(IgnoreItemSheet*)sender
{
    _ignoreSheet = nil;
}

#pragma mark - NSTableViwe Delegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)sender
{
    if (sender == _channelTable) {
        return _config.channels.count;
    }
    else {
        return _config.ignores.count;
    }
}

- (id)tableView:(NSTableView *)sender objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
    if (sender == _channelTable) {
        IRCChannelConfig* c = [_config.channels objectAtIndex:row];
        NSString* columnId = [column identifier];

        if ([columnId isEqualToString:@"name"]) {
            return c.name;
        }
        else if ([columnId isEqualToString:@"pass"]) {
            return c.password;
        }
        else if ([columnId isEqualToString:@"join"]) {
            return @(c.autoJoin);
        }
    }
    else {
        IgnoreItem* g = [_config.ignores objectAtIndex:row];
        NSString* columnId = [column identifier];

        if ([columnId isEqualToString:@"nick"]) {
            return g.displayNick;
        }
        else if ([columnId isEqualToString:@"message"]) {
            return g.displayText;
        }
    }

    return nil;
}

- (void)tableView:(NSTableView *)sender setObjectValue:(id)obj forTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
    if (sender == _channelTable) {
        IRCChannelConfig* c = [_config.channels objectAtIndex:row];
        NSString* columnId = [column identifier];

        if ([columnId isEqualToString:@"join"]) {
            c.autoJoin = [obj intValue] != 0;
        }
    }
    else {
        ;
    }
}

- (void)tableViewSelectionDidChange:(NSNotification *)note
{
    id sender = [note object];

    if (sender == _channelTable) {
        [self updateChannelsPage];
    }
    else {
        [self updateIgnoresPage];
    }
}

- (void)tableViewDoubleClicked:(id)sender
{
    if (sender == _channelTable) {
        [self editChannel:nil];
    }
    else {
        [self editIgnore:nil];
    }
}

- (BOOL)tableView:(NSTableView *)sender writeRowsWithIndexes:(NSIndexSet *)rows toPasteboard:(NSPasteboard *)pboard
{
    if (sender == _channelTable) {
        NSArray* ary = [NSArray arrayWithObject:@([rows firstIndex])];
        [pboard declareTypes:TABLE_ROW_TYPES owner:self];
        [pboard setPropertyList:ary forType:TABLE_ROW_TYPE];
    }
    else {
        ;
    }
    return YES;
}

- (NSDragOperation)tableView:(NSTableView *)sender validateDrop:(id < NSDraggingInfo >)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)op
{
    if (sender == _channelTable) {
        NSPasteboard* pboard = [info draggingPasteboard];
        if (op == NSTableViewDropAbove && [pboard availableTypeFromArray:TABLE_ROW_TYPES]) {
            return NSDragOperationGeneric;
        }
        else {
            return NSDragOperationNone;
        }
    }
    else {
        return NSDragOperationNone;
    }
}

- (BOOL)tableView:(NSTableView *)sender acceptDrop:(id < NSDraggingInfo >)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)op
{
    if (sender == _channelTable) {
        NSPasteboard* pboard = [info draggingPasteboard];
        if (op == NSTableViewDropAbove && [pboard availableTypeFromArray:TABLE_ROW_TYPES]) {
            NSArray* selectedRows = [pboard propertyListForType:TABLE_ROW_TYPE];
            int sel = [[selectedRows objectAtIndex:0] intValue];

            NSMutableArray* ary = _config.channels;
            IRCChannelConfig* target = [ary objectAtIndex:sel];

            NSMutableArray* low = [[ary subarrayWithRange:NSMakeRange(0, row)] mutableCopy];
            NSMutableArray* high = [[ary subarrayWithRange:NSMakeRange(row, ary.count - row)] mutableCopy];

            [low removeObjectIdenticalTo:target];
            [high removeObjectIdenticalTo:target];

            [ary removeAllObjects];

            [ary addObjectsFromArray:low];
            [ary addObject:target];
            [ary addObjectsFromArray:high];

            [self reloadChannelTable];

            sel = [ary indexOfObjectIdenticalTo:target];
            if (0 <= sel) {
                [_channelTable selectItemAtIndex:sel];
            }

            return YES;
        }
    }
    else {
        ;
    }
    return NO;
}

#pragma mark - NSWindow Delegate

- (void)windowWillClose:(NSNotification*)note
{
    [_channelTable unregisterDraggedTypes];

    if ([_delegate respondsToSelector:@selector(serverDialogWillClose:)]) {
        [_delegate serverDialogWillClose:self];
    }
}

#pragma mark - Servers

+ (NSArray*)availableServers
{
    static NSMutableArray* servers = nil;
    if (!servers) {
        servers = [NSMutableArray new];

        if ([NSLocale prefersJapaneseLanguage]) {
            [servers addObject:@"irc.ircnet.ne.jp (IRCnet)"];
            [servers addObject:@"-"];
            [servers addObject:@"irc.friend-chat.jp (Friend)"];
            [servers addObject:@"irc.2ch.net (2ch)"];
            [servers addObject:@"irc.cre.ne.jp (cre)"];
            [servers addObject:@"-"];
            [servers addObject:@"chat.freenode.net (freenode)"];
            [servers addObject:@"eu.undernet.org (Undernet)"];
            [servers addObject:@"irc.quakenet.org (QuakeNet)"];
            [servers addObject:@"chat1.ustream.tv (Ustream)"];
        }
        else {
            [servers addObject:@"chat.freenode.net (freenode)"];
            [servers addObject:@"irc.efnet.net (EFnet)"];
            [servers addObject:@"us.undernet.org (Undernet)"];
            [servers addObject:@"eu.undernet.org (Undernet)"];
            [servers addObject:@"irc.quakenet.org (QuakeNet)"];
            [servers addObject:@"uk.quakenet.org (QuakeNet)"];
            [servers addObject:@"irc.mozilla.org (Mozilla)"];
            [servers addObject:@"chat1.ustream.tv (Ustream)"];
        }
    }
    return servers;
}

@end
