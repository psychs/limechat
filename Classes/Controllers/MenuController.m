// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "MenuController.h"
#import <WebKit/WebKit.h>
#import "Preferences.h"
#import "IRC.h"
#import "IRCWorld.h"
#import "IRCClient.h"
#import "IRCChannel.h"
#import "MemberListView.h"
#import "ServerDialog.h"
#import "ChannelDialog.h"
#import "URLOpener.h"
#import "GTMNSString+URLArguments.h"
#import "NSPasteboardHelper.h"
#import "NSStringHelper.h"
#import "NSDictionaryHelper.h"

#ifndef TARGET_APP_STORE
#import "Sparkle/Sparkle.h"
#endif


#define CONNECTED           (u && u.isConnected)
#define NOT_CONNECTED       (u && !u.isConnected)
#define LOGIN               (u && u.isLoggedIn)
#define ACTIVE              (LOGIN && c && c.isActive)
#define NOT_ACTIVE          (LOGIN && c && !c.isActive)
#define ACTIVE_CHANNEL      (ACTIVE && c.isChannel)
#define ACTIVE_CHANTALK     (ACTIVE && (c.isChannel || c.isTalk))
#define LOGIN_CHANTALK      (LOGIN && (!c || c.isChannel || c.isTalk))
#define IS_OP               (ACTIVE_CHANNEL && c.isOp)
#define KEY_WINDOW          ([_window isKeyWindow])


@implementation MenuController
{
    id _sparkleUpdater;
    PreferencesController* _preferencesController;
    NSMutableArray* _serverDialogs;
    NSMutableArray* _channelDialogs;
    NickSheet* _nickSheet;
    ModeSheet* _modeSheet;
    TopicSheet* _topicSheet;
    PasteSheet* _pasteSheet;
    InviteSheet* _inviteSheet;
    NSOpenPanel* _fileSendPanel;
    NSArray* _fileSendTargets;
    int _fileSendUID;
}

- (id)init
{
    self = [super init];
    if (self) {
        _serverDialogs = [NSMutableArray new];
        _channelDialogs = [NSMutableArray new];
    }
    return self;
}

- (void)setUp
{
#ifdef TARGET_APP_STORE
    [[_checkForUpdateItem menu] removeItem:_checkForUpdateItem];
#else
    _sparkleUpdater = [SUUpdater new];
    [_sparkleUpdater setDelegate:_app];
    [_checkForUpdateItem setTarget:_sparkleUpdater];
    [_checkForUpdateItem setAction:@selector(checkForUpdates:)];
#endif
}

- (void)terminate
{
    for (ServerDialog* d in _serverDialogs) {
        [d close];
    }
    for (ChannelDialog* d in _channelDialogs) {
        [d close];
    }
    if (_preferencesController) {
        [_preferencesController close];
    }
}

- (BOOL)isNickMenu:(NSMenuItem*)item
{
    if (!item) return NO;
    NSInteger tag = item.tag;
    return 2500 <= tag && tag < 3000;
}

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
    IRCClient* u = _world.selectedClient;
    IRCChannel* c = _world.selectedChannel;

    NSInteger tag = item.tag;
    if ([self isNickMenu:item]) tag -= 500;

    switch (tag) {
        case 102:	// preferences
        case 104:	// auto op
        case 201:	// dcc
            return YES;
        case 202:	// close current panel without confirmation
            return KEY_WINDOW && u && c;
        case 203:	// close window / close current panel
            if (KEY_WINDOW) {
                [_closeWindowItem setTitle:NSLocalizedString(@"CloseCurrentPanelMenuTitle", nil)];
                return u && c;
            }
            else {
                [_closeWindowItem setTitle:NSLocalizedString(@"CloseWindowMenuTitle", nil)];
                return YES;
            }
        case 313:	// paste
        {
            if (![[NSPasteboard generalPasteboard] hasStringContent]) {
                return NO;
            }
            NSWindow* win = [NSApp keyWindow];
            if (!win) return NO;
            id t = [win firstResponder];
            if (!t) return NO;
            if (win == _window) {
                return YES;
            }
            else if ([t respondsToSelector:@selector(paste:)]) {
                if ([t respondsToSelector:@selector(validateMenuItem:)]) {
                    return [t validateMenuItem:item];
                }
                return YES;
            }
        }
        case 324:	// use selection for find
        {
            NSWindow* win = [NSApp keyWindow];
            if (!win) return NO;
            id t = [win firstResponder];
            if (!t) return NO;
            NSString* klass = [t className];
            if ([klass isEqualToString:@"WebHTMLView"]) {
                return YES;
            }
            if ([t respondsToSelector:@selector(writeSelectionToPasteboard:type:)]) {
                return YES;
            }
            return NO;
        }
        case 331:	// search in google
        {
            LogView* web = [self currentWebView];
            if (!web) return NO;
            return [web hasSelection];
        }
        case 332:	// paste my address
        {
            if (![_window isKeyWindow]) return NO;
            id t = [_window firstResponder];
            if (!t) return NO;
            IRCClient* u = _world.selectedClient;
            if (!u || !u.myAddress) return NO;
            return YES;
        }
        case 333:	// paste dialog
        case 334:	// copy log as html
        case 335:	// copy console log as html
        case 411:	// mark scrollback
        case 412:	// clear mark
        case 413:	// mark all as read
        case 414:	// go to mark
            return YES;
        case 421:	// make text bigger
            return [_world.consoleLog.view canMakeTextLarger];
        case 422:	// make text smaller
            return [_world.consoleLog.view canMakeTextSmaller];
        case 443:	// reload theme
            return YES;

        case 501:	// connect
            return NOT_CONNECTED;
        case 502:	// disconnect
            return u && (u.isConnected || u.isConnecting);
        case 503:	// cancel isReconnecting
            return u && u.isReconnecting;
        case 511:	// nick
        case 519:	// channel list
            return LOGIN;
        case 521:	// add server
            return YES;
        case 522:	// copy server
            return u != nil;
        case 523:	// delete server
            return NOT_CONNECTED;
        case 541:	// server property
        case 542:	// server auto op
            return u != nil;

        case 601:	// join
            return LOGIN && NOT_ACTIVE && c.isChannel;
        case 602:	// leave
            return ACTIVE;
        case 611:	// mode
            return ACTIVE_CHANNEL;
        case 612:	// topic
            return ACTIVE_CHANNEL;
        case 651:	// add channel
            return u != nil;
        case 652:	// delete channel
            return c != nil;
        case 653:	// channel property
            return c && c.isChannel;
        case 654:	// channel auto op
            return c && c.isChannel;

            // for members
        case 2001:	// whois
        case 2002:	// talk
            return LOGIN_CHANTALK && [self checkSelectedMembers:item];
        case 2005:	// invite
        {
            if (!LOGIN || ![self checkSelectedMembers:item]) return NO;
            int count = 0;
            for (IRCChannel* e in u.channels) {
                if (e != c && e.isChannel) {
                    ++count;
                }
            }
            return count > 0;
        }
        case 2003:	// give op
        case 2004:	// deop
        case 2031:	// kick
        case 2041:	// give voice
        case 2042:	// devoice
            return IS_OP && [self checkSelectedMembers:item];
        case 2011:	// dcc send file
            return LOGIN_CHANTALK && [self checkSelectedMembers:item] && u.myAddress;
        case 2021:	// register to auto op
            return [self checkSelectedMembers:item];
        case 2101 ... 2105:	// CTCP
            return LOGIN_CHANTALK && [self checkSelectedMembers:item];
        case 2032:	// ban
        case 2033:	// kick & ban
            return IS_OP && [self checkSelectedMembers:item] && c.isWhoInit;

        case 3001:	// copy url
        case 3002:	// copy address
        case 3201:	// open channel
        case 3301:	// join channel
            return YES;
    }

    return YES;
}

#pragma mark - Utilities

- (LogView*)currentWebView
{
    id t = [_window firstResponder];
    while ([t isKindOfClass:[NSView class]]) {
        if ([t isKindOfClass:[LogView class]]) {
            return t;
        }
        t = [t superview];
    }
    return nil;
}

- (BOOL)checkSelectedMembers:(NSMenuItem*)item
{
    if ([self isNickMenu:item]) {
        return _pointedNick != nil;
    }
    else {
        return [_memberList countSelectedRows] > 0;
    }
}

- (NSArray*)selectedMembers:(NSMenuItem*)sender
{
    IRCChannel* c = _world.selectedChannel;
    if (!c) {
        if ([self isNickMenu:sender]) {
            IRCUser* m = [IRCUser new];
            m.isupport = c.client.isupport;
            m.nick = _pointedNick;
            return [NSArray arrayWithObject:m];
        }
        else {
            return [NSArray array];
        }
    }
    else {
        if ([self isNickMenu:sender]) {
            IRCUser* m = [c findMember:_pointedNick];
            if (m) {
                return [NSArray arrayWithObject:m];
            }
            else {
                return [NSArray array];
            }
        }
        else {
            NSMutableArray* ary = [NSMutableArray array];
            NSIndexSet* indexes = [_memberList selectedRowIndexes];
            for (NSUInteger i=[indexes firstIndex]; i!=NSNotFound; i=[indexes indexGreaterThanIndex:i]) {
                IRCUser* m = [c memberAtIndex:i];
                [ary addObject:m];
            }
            return ary;
        }
    }
}

- (void)deselectMembers:(NSMenuItem*)sender
{
    if (![self isNickMenu:sender]) {
        [_memberList deselectAll:nil];
    }
}

#pragma mark - Menu Items

- (void)onPreferences:(id)sender
{
    if (!_preferencesController) {
        _preferencesController = [PreferencesController new];
        _preferencesController.delegate = self;
    }
    [_preferencesController show];
}

- (void)preferencesDialogWillClose:(PreferencesController*)sender
{
    [_world preferencesChanged];
}

- (void)onAutoOp:(id)sender
{
}

- (void)onDcc:(id)sender
{
    [_world.dcc show:YES];
}

- (void)onMainWindow:(id)sender
{
    [_window makeKeyAndOrderFront:nil];
}

- (void)onHelp:(id)sender
{
    [URLOpener openAndActivate:[NSURL URLWithString:@"http://limechat.net/mac/"]];
}

- (void)onCloseWindow:(id)sender
{
    if ([_window isKeyWindow]) {
        // for main window
        IRCClient* u = _world.selectedClient;
        IRCChannel* c = _world.selectedChannel;
        if (u && c) {
            if (c.isChannel && c.isActive) {
                NSString* message = [NSString stringWithFormat:@"Close %@ ?", c.name];

                NSAlert *alert = [[NSAlert alloc] init];
                alert.messageText = message;
                alert.informativeText = @"";
                [alert addButtonWithTitle:@"Close"];
                [alert addButtonWithTitle:@"Cancel"];
                NSModalResponse result = [alert runModal];
                if (result != NSAlertFirstButtonReturn) {
                    return;
                }
            }
            [_world destroyChannel:c];
            [_world save];
        }
    }
    else {
        // for other windows
        [[NSApp keyWindow] performClose:nil];
    }
}

- (void)onCloseCurrentPanel:(id)sender
{
    IRCClient* u = _world.selectedClient;
    IRCChannel* c = _world.selectedChannel;
    if (u && c) {
        [_world destroyChannel:c];
        [_world save];
    }
}

- (void)startPasteSheetWithContent:(NSString*)content nick:(NSString*)nick uid:(int)uid cid:(int)cid editMode:(BOOL)editMode
{
    if (_pasteSheet) return;

    _pasteSheet = [PasteSheet new];
    _pasteSheet.delegate = self;
    _pasteSheet.parentWindow = _window;
    _pasteSheet.uid = uid;
    _pasteSheet.cid = cid;
    _pasteSheet.nick = nick;
    _pasteSheet.editMode = editMode;
    _pasteSheet.originalText = content;
    _pasteSheet.command = [Preferences pasteCommand];

    NSDictionary* dic = [Preferences loadWindowStateWithName:@"paste_sheet"];
    if (dic) {
        int w = [dic intForKey:@"w"];
        int h = [dic intForKey:@"h"];
        if (w > 0 && h > 0) {
            _pasteSheet.size = NSMakeSize(w, h);
        }
    }

    [_pasteSheet start];
}

- (void)pasteSheet:(PasteSheet*)sender onPasteText:(NSString*)s
{
    IRCClient* u = [_world findClientById:_pasteSheet.uid];
    IRCChannel* c = [_world findChannelByClientId:_pasteSheet.uid channelId:_pasteSheet.cid];
    if (!u || !c) return;

    NSArray* lines = [s splitIntoLines];
    for (NSString* line in lines) {
        if (line.length) {
            [u sendText:line command:[_pasteSheet.command uppercaseString] channel:c];
        }
    }
}

- (void)pasteSheetOnCancel:(PasteSheet*)sender
{
    if (_pasteSheet.editMode) {
        [_text setStringValue:_pasteSheet.originalText];
        [_world focusInputText];
    }
}

- (void)pasteSheetWillClose:(PasteSheet*)sender
{
    NSSize size = _pasteSheet.size;
    NSDictionary* dic = [NSDictionary dictionaryWithObjectsAndKeys:
                         @(size.width), @"w",
                         @(size.height), @"h",
                         nil];
    [Preferences saveWindowState:dic name:@"paste_sheet"];

    if (!_pasteSheet.isShortText) {
        [Preferences setPasteCommand:_pasteSheet.command];
    }

    _pasteSheet = nil;
}

- (void)onPaste:(id)sender
{
    NSPasteboard* pb = [NSPasteboard generalPasteboard];
    if (![pb hasStringContent]) return;

    NSWindow* win = [NSApp keyWindow];
    if (!win) return;
    id t = [win firstResponder];
    if (!t) return;

    if (win == _window) {
        NSString* s = [pb stringContent];
        if (!s.length) return;

        BOOL multiLine = NO;
        NSArray* lines = [s splitIntoLines];
        if (lines.count > 2) {
            multiLine = YES;
        }
        else if (lines.count == 2) {
            NSString* lastLine = [lines objectAtIndex:1];
            multiLine = lastLine.length > 0;
        }
        IRCChannel* c = _world.selectedChannel;

        if (c && multiLine) {
            // multi line
            IRCClient* u = c.client;
            [self startPasteSheetWithContent:s nick:u.myNick uid:u.uid cid:c.uid editMode:NO];
        }
        else {
            // single line
            if (![t isKindOfClass:[NSTextView class]]) {
                [_world focusInputText];
            }
            NSText* e = [win fieldEditor:NO forObject:_text];
            [e paste:nil];
        }
    }
    else {
        if ([t respondsToSelector:@selector(paste:)]) {
            BOOL validated = YES;
            if ([t respondsToSelector:@selector(validateMenuItem:)]) {
                validated = [t validateMenuItem:sender];
            }
            if (validated) {
                [t paste:sender];
            }
        }
    }
}

- (void)onPasteDialog:(id)sender
{
    IRCClient* u = _world.selectedClient;
    IRCChannel* c = _world.selectedChannel;
    if (!u || !c) return;

    NSString* s = _text.stringValue;
    [_text setStringValue:@""];
    [self startPasteSheetWithContent:s nick:u.myNick uid:u.uid cid:c.uid editMode:YES];
}

- (void)onUseSelectionForFind:(id)sender
{
    NSWindow* win = [NSApp keyWindow];
    if (!win) return;
    id t = [win firstResponder];
    if (!t) return;

    NSString* klass = [t className];
    if ([klass isEqualToString:@"WebHTMLView"]) {
        while ([t isKindOfClass:[NSView class]]) {
            if ([t isKindOfClass:[LogView class]]) {
                NSPasteboard* pb = [NSPasteboard pasteboardWithName:NSFindPboard];
                [pb setStringContent:[t selection]];
            }
            t = [t superview];
        }
    }
    else if ([t respondsToSelector:@selector(writeSelectionToPasteboard:type:)]) {
        NSPasteboard* pb = [NSPasteboard pasteboardWithName:NSFindPboard];
        [pb declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
        [t writeSelectionToPasteboard:pb type:NSStringPboardType];
    }
}

- (void)onPasteMyAddress:(id)sender
{
    if (![_window isKeyWindow]) return;

    id t = [_window firstResponder];
    if (!t) return;

    IRCClient* u = _world.selectedClient;
    if (!u || !u.myAddress) return;

    if (![t isKindOfClass:[NSTextView class]]) {
        [_world focusInputText];
    }
    NSText* fe = [_window fieldEditor:NO forObject:_text];
    [fe replaceCharactersInRange:[fe selectedRange] withString:u.myAddress];
    [fe scrollRangeToVisible:[fe selectedRange]];
}

- (void)onSearchWeb:(id)sender
{
    LogView* web = [self currentWebView];
    if (!web) return;
    NSString* s = [web selection];
    if (s.length) {
        s = [s gtm_stringByEscapingForURLArgument];
        NSString* urlStr = [NSString stringWithFormat:@"http://www.google.com/search?ie=UTF-8&q=%@", s];
        [URLOpener open:[NSURL URLWithString:urlStr]];
    }
}

- (void)onCopyLogAsHtml:(id)sender
{
    IRCTreeItem* sel = _world.selected;
    if (!sel) return;
    NSString* s = [sel.log.view contentString];
    [[NSPasteboard generalPasteboard] setStringContent:s];
}

- (void)onCopyConsoleLogAsHtml:(id)sender
{
    NSString* s = [_world.consoleLog.view contentString];
    [[NSPasteboard generalPasteboard] setStringContent:s];
}

- (void)onMarkScrollback:(id)sender
{
    IRCTreeItem* sel = _world.selected;
    if (!sel) return;
    [sel.log mark];
}

- (void)onClearMark:(id)sender
{
    IRCTreeItem* sel = _world.selected;
    if (!sel) return;
    [sel.log unmark];
}

- (void)onGoToMark:(id)sender
{
    IRCTreeItem* sel = _world.selected;
    if (!sel) return;
    [sel.log goToMark];
}

- (void)onMarkAllAsRead:(id)sender
{
    [_world markAllAsRead];
}

- (void)onMarkAllAsReadAndMarkAllScrollbacks:(id)sender
{
    [_world markAllAsRead];
    [_world markAllScrollbacks];
}

- (void)onMakeTextBigger:(id)sender
{
    [_world changeTextSize:YES];
}

- (void)onMakeTextSmaller:(id)sender
{
    [_world changeTextSize:NO];
}

- (void)onReloadTheme:(id)sender
{
    [_world reloadTheme];
}

- (void)onConnect:(id)sender
{
    IRCClient* u = _world.selectedClient;
    if (!u) return;
    [u connect];
}

- (void)onDisconnect:(id)sender
{
    IRCClient* u = _world.selectedClient;
    if (!u) return;
    [u quit];
    [u cancelReconnect];
}

- (void)onCancelReconnecting:(id)sender
{
    IRCClient* u = _world.selectedClient;
    if (!u) return;
    [u cancelReconnect];
}

- (void)onNick:(id)sender
{
    if (_nickSheet) return;

    IRCClient* u = _world.selectedClient;
    if (!u) return;

    _nickSheet = [NickSheet new];
    _nickSheet.delegate = self;
    _nickSheet.parentWindow = _window;
    _nickSheet.uid = u.uid;
    [_nickSheet start:u.myNick];
}

- (void)nickSheet:(NickSheet*)sender didInputNick:(NSString*)newNick
{
    int uid = sender.uid;
    IRCClient* u = [_world findClientById:uid];
    if (!u) return;
    [u changeNick:newNick];
}

- (void)nickSheetWillClose:(NickSheet*)sender
{
    _nickSheet = nil;
}

- (void)onChannelList:(id)sender
{
    IRCClient* u = _world.selectedClient;
    if (!u) return;
    [u createChannelListDialog];
}

- (void)onAddServer:(id)sender
{
    ServerDialog* d = [ServerDialog new];
    d.delegate = self;
    d.parentWindow = _window;
    d.config = [IRCClientConfig new];
    d.uid = -1;
    [_serverDialogs addObject:d];
    [d startWithIgnoreTab:NO];
}

- (void)onCopyServer:(id)sender
{
    IRCClient* u = _world.selectedClient;
    if (!u) return;

    IRCClientConfig* config = u.storedConfig;
    config.name = [config.name stringByAppendingString:@"_"];

    IRCClient* n = [_world createClient:config reload:YES];
    [_world expandClient:n];
    [_world save];
}

- (void)onDeleteServer:(id)sender
{
    IRCClient* u = _world.selectedClient;
    if (!u || u.isConnected) return;

    NSString* message = [NSString stringWithFormat:@"Delete %@ ?", u.name];

    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = message;
    alert.informativeText = @"";
    [alert addButtonWithTitle:@"Delete"];
    [alert addButtonWithTitle:@"Cancel"];
    NSModalResponse result = [alert runModal];
    if (result != NSAlertFirstButtonReturn) {
        return;
    }

    [_world destroyClient:u];
    [_world save];
}

- (void)showServerPropertyDialog:(IRCClient*)u ignore:(BOOL)ignore
{
    if (!u) return;

    if (u.propertyDialog) {
        [u.propertyDialog show];
        return;
    }

    ServerDialog* d = [ServerDialog new];
    d.delegate = self;
    d.parentWindow = _window;
    d.config = u.storedConfig;
    d.uid = u.uid;
    [_serverDialogs addObject:d];
    [d startWithIgnoreTab:ignore];
}

- (void)onServerProperties:(id)sender
{
    [self showServerPropertyDialog:_world.selectedClient ignore:NO];
}

- (void)serverDialogOnOK:(ServerDialog*)sender
{
    if (sender.uid < 0) {
        // create
        [_world createClient:sender.config reload:YES];
    }
    else {
        // update
        IRCClient* u = [_world findClientById:sender.uid];
        if (!u) return;
        [u updateConfig:sender.config];
    }
    [_world save];
}

- (void)serverDialogWillClose:(ServerDialog*)sender
{
    [_serverDialogs removeObjectIdenticalTo:sender];

    IRCClient* u = _world.selectedClient;
    if (!u) return;
    u.propertyDialog = nil;
}

- (void)onServerAutoOp:(id)sender
{
}

- (void)onJoin:(id)sender
{
    IRCClient* u = _world.selectedClient;
    IRCChannel* c = _world.selectedChannel;
    if (!u || !c || !u.isLoggedIn || c.isActive || !c.isChannel) return;
    [u joinChannel:c];
}

- (void)onLeave:(id)sender
{
    IRCClient* u = _world.selectedClient;
    IRCChannel* c = _world.selectedChannel;
    if (!u || !c || !u.isLoggedIn || !c.isActive) return;
    if (c.isChannel) {
        [u partChannel:c];
    }
    else {
        [_world destroyChannel:c];
    }
}

- (void)onTopic:(id)sender
{
    IRCClient* u = _world.selectedClient;
    IRCChannel* c = _world.selectedChannel;
    if (!u || !c) return;
    if (_topicSheet) return;

    _topicSheet = [TopicSheet new];
    _topicSheet.delegate = self;
    _topicSheet.parentWindow = _window;
    _topicSheet.uid = u.uid;
    _topicSheet.cid = c.uid;
    [_topicSheet start:c.topic];
}

- (void)topicSheet:(TopicSheet*)sender onOK:(NSString*)topic
{
    IRCClient* u = [_world findClientById:sender.uid];
    IRCChannel* c = [_world findChannelByClientId:sender.uid channelId:sender.cid];
    if (!u || !c) return;

    [u send:TOPIC, c.name, topic, nil];
}

- (void)topicSheetWillClose:(TopicSheet*)sender
{
    _topicSheet = nil;
}

- (void)onMode:(id)sender
{
    IRCClient* u = _world.selectedClient;
    IRCChannel* c = _world.selectedChannel;
    if (!u || !c) return;
    if (_modeSheet) return;

    _modeSheet = [ModeSheet new];
    _modeSheet.delegate = self;
    _modeSheet.parentWindow = _window;
    _modeSheet.uid = u.uid;
    _modeSheet.cid = c.uid;
    _modeSheet.mode = [c.mode mutableCopy];
    _modeSheet.channelName = c.name;
    [_modeSheet start];
}

- (void)modeSheetOnOK:(ModeSheet*)sender
{
    IRCClient* u = [_world findClientById:sender.uid];
    IRCChannel* c = [_world findChannelByClientId:sender.uid channelId:sender.cid];
    if (!u || !c) return;

    NSString* changeStr = [c.mode getChangeCommand:sender.mode];
    if (changeStr.length) {
        NSString* line = [NSString stringWithFormat:@"%@ %@ %@", MODE, c.name, changeStr];
        [u sendLine:line];
    }
}

- (void)modeSheetWillClose:(ModeSheet*)sender
{
    _modeSheet = nil;
}

- (void)onAddChannel:(id)sender
{
    IRCClient* u = _world.selectedClient;
    IRCChannel* c = _world.selectedChannel;
    if (!u) return;

    IRCChannelConfig* config;
    if (c && c.isChannel) {
        config = [c.config mutableCopy];
    }
    else {
        config = [IRCChannelConfig new];
    }
    config.name = @"";

    ChannelDialog* d = [ChannelDialog new];
    d.delegate = self;
    d.parentWindow = _window;
    d.config = config;
    d.uid = u.uid;
    d.cid = -1;
    [_channelDialogs addObject:d];
    [d start];
}

- (void)onDeleteChannel:(id)sender
{
    IRCChannel* c = _world.selectedChannel;
    if (!c) return;
    [_world destroyChannel:c];
    [_world save];
}

- (void)onChannelProperties:(id)sender
{
    IRCClient* u = _world.selectedClient;
    IRCChannel* c = _world.selectedChannel;
    if (!u || !c) return;

    if (c.propertyDialog) {
        [c.propertyDialog show];
        return;
    }

    ChannelDialog* d = [ChannelDialog new];
    d.delegate = self;
    d.parentWindow = _window;
    d.config = [c.config mutableCopy];
    d.uid = u.uid;
    d.cid = c.uid;
    [_channelDialogs addObject:d];
    [d start];
}

- (void)channelDialogOnOK:(ChannelDialog*)sender
{
    if (sender.cid < 0) {
        // create
        IRCClient* u = [_world findClientById:sender.uid];
        if (!u) return;
        [_world createChannel:sender.config client:u reload:YES adjust:YES];
        [_world expandClient:u];
        [_world save];
    }
    else {
        // update
        IRCChannel* c = [_world findChannelByClientId:sender.uid channelId:sender.cid];
        if (!c) return;
        [c updateConfig:sender.config];
    }

    [_world save];
}

- (void)channelDialogWillClose:(ChannelDialog*)sender
{
    if (sender.cid >= 0) {
        IRCChannel* c = [_world findChannelByClientId:sender.uid channelId:sender.cid];
        c.propertyDialog = nil;
    }

    [_channelDialogs removeObjectIdenticalTo:sender];
}

- (void)onChannelAutoOp:(id)sender
{
}

- (void)whoisSelectedMembers:(id)sender deselect:(BOOL)deselect
{
    IRCClient* u = _world.selectedClient;
    if (!u) return;

    for (IRCUser* m in [self selectedMembers:sender]) {
        [u sendWhois:m.nick];
    }

    if (deselect) {
        [self deselectMembers:sender];
    }
}

- (void)talkSelectedMembers:(id)sender deselect:(BOOL)deselect
{
    IRCClient* u = _world.selectedClient;
    if (!u) return;

    for (IRCUser* m in [self selectedMembers:sender]) {
        IRCChannel* c = [u findChannel:m.nick];
        if (!c) {
            c = [_world createTalk:m.nick client:u];
        }
        [_world select:c];
    }

    if (deselect) {
        [self deselectMembers:sender];
    }
}

- (void)memberListDoubleClicked:(id)sender
{
    MemberListView* view = sender;
    NSPoint pt = [_window mouseLocationOutsideOfEventStream];
    pt = [view convertPoint:pt fromView:nil];
    int n = [view rowAtPoint:pt];
    if (n >= 0) {
        if ([[view selectedRowIndexes] count] > 0) {
            [view selectItemAtIndex:n];
        }

        switch ([Preferences doubleClickUserAction]) {
            case DOUBLE_CLICK_USER_ACTION_TALK:
                [self talkSelectedMembers:nil deselect:NO];
                break;
            case DOUBLE_CLICK_USER_ACTION_WHOIS:
                [self whoisSelectedMembers:nil deselect:NO];
                break;
        }
    }
}

- (void)onMemberWhois:(id)sender
{
    [self whoisSelectedMembers:sender deselect:YES];
}

- (void)onMemberTalk:(id)sender
{
    [self talkSelectedMembers:sender deselect:YES];
}

- (void)changeOp:(id)sender mode:(char)mode value:(BOOL)value
{
    IRCClient* u = _world.selectedClient;
    IRCChannel* c = _world.selectedChannel;
    if (!u || !u.isLoggedIn || !c || !c.isActive || !c.isChannel || !c.isOp) return;

    [u changeOp:c users:[self selectedMembers:sender] mode:mode value:value];
    [self deselectMembers:sender];
}

- (void)onMemberGiveOp:(id)sender
{
    [self changeOp:sender mode:'o' value:YES];
}

- (void)onMemberDeop:(id)sender
{
    [self changeOp:sender mode:'o' value:NO];
}

- (void)onMemberInvite:(id)sender
{
    if (_inviteSheet) return;

    IRCClient* u = _world.selectedClient;
    IRCChannel* c = _world.selectedChannel;
    if (!u || !u.isLoggedIn || !c) return;

    NSMutableArray* nicks = [NSMutableArray array];
    for (IRCUser* m in [self selectedMembers:sender]) {
        [nicks addObject:m.nick];
    }

    NSMutableArray* channels = [NSMutableArray array];
    for (IRCChannel* e in u.channels) {
        if (c != e && e.isChannel) {
            [channels addObject:e.name];
        }
    }

    if (!channels.count) return;

    _inviteSheet = [InviteSheet new];
    _inviteSheet.delegate = self;
    _inviteSheet.parentWindow = _window;
    _inviteSheet.nicks = nicks;
    _inviteSheet.uid = u.uid;
    [_inviteSheet startWithChannels:channels];
}

- (void)inviteSheet:(InviteSheet*)sender onSelectChannel:(NSString*)channelName
{
    IRCClient* u = [_world findClientById:sender.uid];
    if (!u) return;

    for (NSString* nick in sender.nicks) {
        [u send:INVITE, nick, channelName, nil];
    }
}

- (void)inviteSheetWillClose:(InviteSheet*)sender
{
    _inviteSheet = nil;
}

- (void)onMemberKick:(id)sender
{
    IRCClient* u = _world.selectedClient;
    IRCChannel* c = _world.selectedChannel;
    if (!u || !u.isLoggedIn || !c || !c.isActive || !c.isChannel || !c.isOp) return;

    for (IRCUser* m in [self selectedMembers:sender]) {
        [u kick:c target:m.nick];
    }

    [self deselectMembers:sender];
}

- (void)onMemberBan:(id)sender
{
}

- (void)onMemberKickBan:(id)sender
{
}

- (void)onMemberGiveVoice:(id)sender
{
    [self changeOp:sender mode:'v' value:YES];
}

- (void)onMemberDevoice:(id)sender
{
    [self changeOp:sender mode:'v' value:NO];
}

- (void)onMemberSendFile:(id)sender
{
    if (_fileSendPanel) {
        [_fileSendPanel cancel:nil];
    }

    IRCClient* u = _world.selectedClient;
    if (!u) return;

    _fileSendTargets = [self selectedMembers:sender];

    if (!_fileSendTargets.count) return;

    _fileSendUID = u.uid;

    NSOpenPanel* d = [NSOpenPanel openPanel];
    [d setCanChooseFiles:YES];
    [d setCanChooseDirectories:NO];
    [d setResolvesAliases:YES];
    [d setAllowsMultipleSelection:YES];
    [d setCanCreateDirectories:NO];
    d.directoryURL = [NSURL fileURLWithPath:@"~/Desktop" isDirectory:YES];

    __block MenuController* blockSelf = self;
    [d beginWithCompletionHandler:^(NSInteger result) {
        [blockSelf fileSendPanelDidEnd:d returnCode:result contextInfo:NULL];
    }];

    _fileSendPanel = d;
}

- (void)fileSendPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if (returnCode == NSModalResponseOK) {
        NSArray* files = [panel URLs];

        for (IRCUser* m in _fileSendTargets) {
            for (NSURL* fileUrl in files) {
                NSString* fname = [fileUrl path];
                [_world.dcc addSenderWithUID:_fileSendUID nick:m.nick fileName:fname autoOpen:YES];
            }
        }
    }

    _fileSendPanel = nil;
    _fileSendTargets = nil;
}

- (void)onMemberPing:(id)sender
{
    IRCClient* u = _world.selectedClient;
    if (!u) return;

    for (IRCUser* m in [self selectedMembers:sender]) {
        [u sendCTCPPing:m.nick];
    }

    [self deselectMembers:sender];
}

- (void)onMemberTime:(id)sender
{
    IRCClient* u = _world.selectedClient;
    if (!u) return;

    for (IRCUser* m in [self selectedMembers:sender]) {
        [u sendCTCPQuery:m.nick command:TIME text:nil];
    }

    [self deselectMembers:sender];
}

- (void)onMemberVersion:(id)sender
{
    IRCClient* u = _world.selectedClient;
    if (!u) return;

    for (IRCUser* m in [self selectedMembers:sender]) {
        [u sendCTCPQuery:m.nick command:VERSION text:nil];
    }

    [self deselectMembers:sender];
}

- (void)onMemberUserInfo:(id)sender
{
    IRCClient* u = _world.selectedClient;
    if (!u) return;

    for (IRCUser* m in [self selectedMembers:sender]) {
        [u sendCTCPQuery:m.nick command:USERINFO text:nil];
    }

    [self deselectMembers:sender];
}

- (void)onMemberClientInfo:(id)sender
{
    IRCClient* u = _world.selectedClient;
    if (!u) return;

    for (IRCUser* m in [self selectedMembers:sender]) {
        [u sendCTCPQuery:m.nick command:CLIENTINFO text:nil];
    }

    [self deselectMembers:sender];
}

- (void)onMemberAutoOp:(id)sender
{
}

- (void)onCopyUrl:(id)sender
{
    if (!_pointedUrl) return;
    [[NSPasteboard generalPasteboard] setStringContent:_pointedUrl];
    self.pointedUrl = nil;
}

- (void)onJoinChannel:(id)sender
{
    if (!_pointedChannelName) return;
    IRCClient* u = _world.selectedClient;
    if (!u || !u.isLoggedIn) return;
    [u send:JOIN, _pointedChannelName, nil];
}

- (void)onCopyAddress:(id)sender
{
    if (!_pointedAddress) return;
    [[NSPasteboard generalPasteboard] setStringContent:_pointedAddress];
    self.pointedAddress = nil;
}

@end
