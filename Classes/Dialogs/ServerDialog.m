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
            [hostCombo addItemWithObjectValue:s];
        }
    }
    return self;
}

- (void)startWithIgnoreTab:(BOOL)ignoreTab
{
    if (_uid < 0) {
        [self.window setTitle:@"New Server"];
    }

    [channelTable setTarget:self];
    [channelTable setDoubleAction:@selector(tableViewDoubleClicked:)];
    [channelTable registerForDraggedTypes:TABLE_ROW_TYPES];

    [ignoreTable setTarget:self];
    [ignoreTable setDoubleAction:@selector(tableViewDoubleClicked:)];
    [ignoreTable registerForDraggedTypes:TABLE_ROW_TYPES];

    [self load];
    [self updateConnectionPage];
    [self updateChannelsPage];
    [self updateIgnoresPage];
    [self encodingChanged:nil];
    [self proxyChanged:nil];
    [self reloadChannelTable];
    [self reloadIgnoreTable];

    if (ignoreTab) {
        [tab selectTabViewItem:[tab tabViewItemAtIndex:IGNORE_TAB_INDEX]];
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
    nameText.stringValue = _config.name;
    autoConnectCheck.state = _config.autoConnect;

    hostCombo.stringValue = _config.host;
    sslCheck.state = _config.useSSL;
    portText.intValue = _config.port;

    nickText.stringValue = _config.nick;
    passwordText.stringValue = _config.password;
    usernameText.stringValue = _config.username;
    realNameText.stringValue = _config.realName;
    nickPasswordText.stringValue = _config.nickPassword;
    saslCheck.state = _config.useSASL;
    if (_config.altNicks.count) {
        altNicksText.stringValue = [_config.altNicks componentsJoinedByString:@" "];
    }
    else {
        altNicksText.stringValue = @"";
    }

    leavingCommentText.stringValue = _config.leavingComment;
    userInfoText.stringValue = _config.userInfo;

    [encodingCombo selectItemWithTag:_config.encoding];
    [fallbackEncodingCombo selectItemWithTag:_config.fallbackEncoding];

    [proxyCombo selectItemWithTag:_config.proxyType];
    proxyHostText.stringValue = _config.proxyHost;
    proxyPortText.intValue = _config.proxyPort;
    proxyUserText.stringValue = _config.proxyUser;
    proxyPasswordText.stringValue = _config.proxyPassword;

    loginCommandsText.string = [_config.loginCommands componentsJoinedByString:@"\n"];
    invisibleCheck.state = _config.invisibleMode;
}

- (void)save
{
    _config.name = nameText.stringValue;
    _config.autoConnect = autoConnectCheck.state;

    _config.host = hostCombo.stringValue;
    _config.useSSL = sslCheck.state;
    _config.port = portText.intValue;

    _config.nick = nickText.stringValue;
    _config.password = passwordText.stringValue;
    _config.username = usernameText.stringValue;
    _config.realName = realNameText.stringValue;
    _config.nickPassword = nickPasswordText.stringValue;
    _config.useSASL = saslCheck.state;

    NSArray* nicks = [altNicksText.stringValue componentsSeparatedByString:@" "];
    [_config.altNicks removeAllObjects];
    for (NSString* s in nicks) {
        if (s.length) {
            [_config.altNicks addObject:s];
        }
    }

    _config.leavingComment = leavingCommentText.stringValue;
    _config.userInfo = userInfoText.stringValue;

    _config.encoding = encodingCombo.selectedTag;
    _config.fallbackEncoding = fallbackEncodingCombo.selectedTag;

    _config.proxyType = proxyCombo.selectedTag;
    _config.proxyHost = proxyHostText.stringValue;
    _config.proxyPort = proxyPortText.intValue;
    _config.proxyUser = proxyUserText.stringValue;
    _config.proxyPassword = proxyPasswordText.stringValue;

    NSArray* commands = [loginCommandsText.string componentsSeparatedByString:@"\n"];
    [_config.loginCommands removeAllObjects];
    for (NSString* s in commands) {
        if (s.length) {
            [_config.loginCommands addObject:s];
        }
    }

    _config.invisibleMode = invisibleCheck.state;
}

- (void)updateConnectionPage
{
    NSString* name = [nameText stringValue];
    NSString* host = [hostCombo stringValue];
    int port = [portText intValue];
    NSString* nick = [nickText stringValue];
    NSString* nickPassword = [nickPasswordText stringValue];

    BOOL enabled = name.length && host.length && ![host isEqualToString:@"-"] && port > 0 && nick.length;
    [okButton setEnabled:enabled];

    BOOL saslEnabled = nickPassword.length > 0;
    [saslCheck setEnabled:saslEnabled];
}

- (void)updateChannelsPage
{
    NSInteger i = [channelTable selectedRow];
    BOOL enabled = (i >= 0);
    [editChannelButton setEnabled:enabled];
    [deleteChannelButton setEnabled:enabled];
}

- (void)reloadChannelTable
{
    [channelTable reloadData];
}

- (void)updateIgnoresPage
{
    NSInteger i = [ignoreTable selectedRow];
    BOOL enabled = (i >= 0);
    [editIgnoreButton setEnabled:enabled];
    [deleteIgnoreButton setEnabled:enabled];
}

- (void)reloadIgnoreTable
{
    [ignoreTable reloadData];
}

#pragma mark -
#pragma mark Actions

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
    int tag = [encodingCombo selectedTag];
    [fallbackEncodingCombo setEnabled:(tag == NSUTF8StringEncoding)];
}

- (void)proxyChanged:(id)sender
{
    int tag = [proxyCombo selectedTag];
    BOOL enabled = (tag == PROXY_SOCKS4 || tag == PROXY_SOCKS5);
    [proxyHostText setEnabled:enabled];
    [proxyPortText setEnabled:enabled];
    [proxyUserText setEnabled:enabled];
    [proxyPasswordText setEnabled:enabled];
    //[sslCheck setEnabled:tag == PROXY_NONE];
}

#pragma mark -
#pragma mark Channel Actions

- (void)addChannel:(id)sender
{
    NSInteger sel = [channelTable selectedRow];
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
    NSInteger sel = [channelTable selectedRow];
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
    NSInteger sel = [channelTable selectedRow];
    if (sel < 0) return;

    [_config.channels removeObjectAtIndex:sel];

    int count = _config.channels.count;
    if (count) {
        if (count <= sel) {
            [channelTable selectItemAtIndex:count - 1];
        }
        else {
            [channelTable selectItemAtIndex:sel];
        }
    }

    [self reloadChannelTable];
}

#pragma mark -
#pragma mark Ignore Actions

- (void)addIgnore:(id)sender
{
    _ignoreSheet = [IgnoreItemSheet new];
    _ignoreSheet.delegate = self;
    _ignoreSheet.window = self.window;
    _ignoreSheet.ignore = [IgnoreItem new];
    _ignoreSheet.newItem = YES;
    [_ignoreSheet start];
}

- (void)editIgnore:(id)sender
{
    NSInteger sel = [ignoreTable selectedRow];
    if (sel < 0) return;

    _ignoreSheet = [IgnoreItemSheet new];
    _ignoreSheet.delegate = self;
    _ignoreSheet.window = self.window;
    _ignoreSheet.ignore = [_config.ignores objectAtIndex:sel];
    [_ignoreSheet start];
}

- (void)deleteIgnore:(id)sender
{
    NSInteger sel = [ignoreTable selectedRow];
    if (sel < 0) return;

    [_config.ignores removeObjectAtIndex:sel];

    int count = _config.ignores.count;
    if (count) {
        if (count <= sel) {
            [ignoreTable selectItemAtIndex:count - 1];
        }
        else {
            [ignoreTable selectItemAtIndex:sel];
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

#pragma mark -
#pragma mark NSTableViwe Delegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)sender
{
    if (sender == channelTable) {
        return _config.channels.count;
    }
    else {
        return _config.ignores.count;
    }
}

- (id)tableView:(NSTableView *)sender objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
    if (sender == channelTable) {
        IRCChannelConfig* c = [_config.channels objectAtIndex:row];
        NSString* columnId = [column identifier];

        if ([columnId isEqualToString:@"name"]) {
            return c.name;
        }
        else if ([columnId isEqualToString:@"pass"]) {
            return c.password;
        }
        else if ([columnId isEqualToString:@"join"]) {
            return [NSNumber numberWithBool:c.autoJoin];
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
    if (sender == channelTable) {
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

    if (sender == channelTable) {
        [self updateChannelsPage];
    }
    else {
        [self updateIgnoresPage];
    }
}

- (void)tableViewDoubleClicked:(id)sender
{
    if (sender == channelTable) {
        [self editChannel:nil];
    }
    else {
        [self editIgnore:nil];
    }
}

- (BOOL)tableView:(NSTableView *)sender writeRowsWithIndexes:(NSIndexSet *)rows toPasteboard:(NSPasteboard *)pboard
{
    if (sender == channelTable) {
        NSArray* ary = [NSArray arrayWithObject:[NSNumber numberWithInt:[rows firstIndex]]];
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
    if (sender == channelTable) {
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
    if (sender == channelTable) {
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
                [channelTable selectItemAtIndex:sel];
            }

            return YES;
        }
    }
    else {
        ;
    }
    return NO;
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification*)note
{
    [channelTable unregisterDraggedTypes];

    if ([_delegate respondsToSelector:@selector(serverDialogWillClose:)]) {
        [_delegate serverDialogWillClose:self];
    }
}

#pragma mark -
#pragma mark Servers

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
