// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "AppController.h"
#import <Carbon/Carbon.h>
#import "Preferences.h"
#import "IRC.h"
#import "IRCTreeItem.h"
#import "IRCWorld.h"
#import "IRCClient.h"
#import "ViewTheme.h"
#import "MemberListViewCell.h"
#import "ImageDownloadManager.h"
#import "NSPasteboardHelper.h"
#import "NSStringHelper.h"
#import "NSDictionaryHelper.h"
#import "NSLocaleHelper.h"
#import "UserNotificationController.h"


#define KInternetEventClass     1196773964
#define KAEGetURL               1196773964


@implementation AppController
{
    WelcomeDialog* _welcomeDialog;
    id<NotificationController> _notifier;
    DCCController* _dcc;
    FieldEditorTextView* _fieldEditor;
    IRCWorld* _world;
    ViewTheme* _viewTheme;
    InputHistory* _inputHistory;
    NickCompletinStatus* _completionStatus;

    BOOL _threeColumns;
    BOOL _terminating;
}

#pragma mark - NSApplication Delegate

- (void)awakeFromNib
{
    NSWindowCollectionBehavior behavior = [_window collectionBehavior];
    behavior |= NSWindowCollectionBehaviorFullScreenPrimary;
    [_window setCollectionBehavior:behavior];

    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(themeDidChange:) name:ThemeDidChangeNotification object:nil];

    NSNotificationCenter* wsnc = [[NSWorkspace sharedWorkspace] notificationCenter];
    [wsnc addObserver:self selector:@selector(computerWillSleep:) name:NSWorkspaceWillSleepNotification object:nil];
    [wsnc addObserver:self selector:@selector(computerDidWakeUp:) name:NSWorkspaceDidWakeNotification object:nil];
    [wsnc addObserver:self selector:@selector(computerWillPowerOff:) name:NSWorkspaceWillPowerOffNotification object:nil];

    // URL handler
    NSAppleEventManager* em = [NSAppleEventManager sharedAppleEventManager];
    [em setEventHandler:self andSelector:@selector(handleURLEvent:withReplyEvent:) forEventClass:KInternetEventClass andEventID:KAEGetURL];

    // hot key
    int keyCode = [Preferences hotKeyKeyCode];
    NSUInteger modifierFlags = [Preferences hotKeyModifierFlags];
    if (keyCode) {
        [(LimeChatApplication*)NSApp registerHotKey:keyCode modifierFlags:modifierFlags];
    }

    _rootSplitter.fixedViewIndex = 1;
    _logSplitter.fixedViewIndex = 1;
    _infoSplitter.fixedViewIndex = 1;
    _treeSplitter.hidden = YES;

    _fieldEditor = [[FieldEditorTextView alloc] initWithFrame:NSZeroRect];
    [_fieldEditor setFieldEditor:YES];
    _fieldEditor.pasteDelegate = self;

    [_fieldEditor setContinuousSpellCheckingEnabled:[Preferences spellCheckEnabled]];
    [_fieldEditor setGrammarCheckingEnabled:[Preferences grammarCheckEnabled]];
    [_fieldEditor setSmartInsertDeleteEnabled:[Preferences smartInsertDeleteEnabled]];
    [_fieldEditor setAutomaticQuoteSubstitutionEnabled:[Preferences quoteSubstitutionEnabled]];
    [_fieldEditor setAutomaticLinkDetectionEnabled:[Preferences linkDetectionEnabled]];
    [_fieldEditor setAutomaticSpellingCorrectionEnabled:[Preferences spellingCorrectionEnabled]];
    [_fieldEditor setAutomaticDashSubstitutionEnabled:[Preferences dashSubstitutionEnabled]];
    [_fieldEditor setAutomaticDataDetectionEnabled:[Preferences dataDetectionEnabled]];
    [_fieldEditor setAutomaticTextReplacementEnabled:[Preferences textReplacementEnabled]];

    [_text setFocusRingType:NSFocusRingTypeNone];

    _viewTheme = [ViewTheme new];
    _viewTheme.name = [Preferences themeName];
    _tree.theme = _viewTheme.other;
    _memberList.theme = _viewTheme.other;
    MemberListViewCell* cell = [MemberListViewCell new];
    [cell setup:_viewTheme.other];
    [[[_memberList tableColumns] objectAtIndex:0] setDataCell:cell];

    [self loadWindowState];
    [_window setAlphaValue:[Preferences themeTransparency]];
    [self set3columnLayout:[Preferences mainWindowLayout] == MAIN_WINDOW_LAYOUT_3_COLUMN];

    IRCWorldConfig* seed = [[IRCWorldConfig alloc] initWithDictionary:[Preferences loadWorld]];

    _world = [IRCWorld new];
    _world.app = self;
    _world.window = _window;
    _world.notifier = _notifier;
    _world.tree = _tree;
    _world.text = _text;
    _world.logBase = _logBase;
    _world.consoleBase = _consoleBase;
    _world.chatBox = _chatBox;
    _world.fieldEditor = _fieldEditor;
    _world.memberList = _memberList;
    [_world setServerMenuItem:_serverMenu];
    [_world setChannelMenuItem:_channelMenu];
    _world.treeMenu = _treeMenu;
    _world.logMenu = _logMenu;
    _world.consoleMenu = _consoleMenu;
    _world.urlMenu = _urlMenu;
    _world.addrMenu = _addrMenu;
    _world.chanMenu = _chanMenu;
    _world.memberMenu = _memberMenu;
    _world.viewTheme = _viewTheme;
    _world.menuController = _menu;
    [_world setup:seed];

    _tree.dataSource = _world;
    _tree.delegate = _world;
    _tree.responderDelegate = _world;
    [_tree reloadData];
    [_world setupTree];

    _menu.app = self;
    _menu.world = _world;
    _menu.window = _window;
    _menu.tree = _tree;
    _menu.memberList = _memberList;
    _menu.text = _text;
    [_menu setUp];

    _memberList.target = _menu;
    [_memberList setDoubleAction:@selector(memberListDoubleClicked:)];
    _memberList.keyDelegate = _world;
    _memberList.dropDelegate = _world;

    _dcc = [DCCController new];
    _dcc.world = _world;
    _dcc.mainWindow = _window;
    _world.dcc = _dcc;

    _notifier = [UserNotificationController new];
    _notifier.delegate = _world;
    _world.notifier = _notifier;

    _inputHistory = [InputHistory new];

    [ImageDownloadManager instance].world = _world;

    [self registerKeyHandlers];
}

- (void)applicationDidFinishLaunching:(NSNotification *)note
{
    [ViewTheme createUserDirectory];

    if (!_world.clients.count) {
        _welcomeDialog = [WelcomeDialog new];
        _welcomeDialog.delegate = self;
        [_welcomeDialog show];
    }
    else {
        [_window makeFirstResponder:_text];
        [_window makeKeyAndOrderFront:nil];
        [_world autoConnect:NO];
    }
}

- (void)applicationDidBecomeActive:(NSNotification *)note
{
    id sel = _world.selected;
    if (sel) {
        [sel resetState];
        [_world updateIcon];
    }

    [_tree setNeedsDisplay];
}

- (void)applicationDidResignActive:(NSNotification *)note
{
    [_tree setNeedsDisplay];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication*)sender hasVisibleWindows:(BOOL)flag
{
    [_window makeKeyAndOrderFront:nil];
    return YES;
}

- (void)applicationDidReceiveHotKey:(id)sender
{
    if (![_window isVisible] || ![NSApp isActive]) {
        [NSApp activateIgnoringOtherApps:YES];
        [_window makeKeyAndOrderFront:nil];
        [_text focus];
    }
    else {
        [NSApp hide:nil];
    }
}

- (BOOL)queryTerminate
{
    if (_terminating) {
        return YES;
    }

    int receiving = [_dcc countReceivingItems];
    int sending = [_dcc countSendingItems];

    if (receiving > 0 || sending > 0) {
        NSMutableString* msg = [NSMutableString stringWithString:@"Now you are "];
        if (receiving > 0) {
            [msg appendFormat:@"receiving %d files", receiving];
        }
        if (sending > 0) {
            if (receiving > 0) {
                [msg appendString:@" and "];
            }
            [msg appendFormat:@"sending %d files", sending];
        }
        [msg appendString:@"."];
        NSInteger result = NSRunAlertPanel(@"Quit LimeChat?", msg, @"Quit", @"Cancel", nil);
        if (result != NSAlertDefaultReturn) {
            return NO;
        }
    }
    else if ([Preferences confirmQuit]) {
        NSInteger result = NSRunAlertPanel(@"Quit LimeChat?", @"", @"Quit", @"Cancel", nil);
        if (result != NSAlertDefaultReturn) {
            return NO;
        }
    }

    return YES;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    if ([self queryTerminate]) {
        return NSTerminateNow;
    }
    else {
        return NSTerminateCancel;
    }
}

- (void)applicationWillTerminate:(NSNotification *)note
{
    // unregister URL handler
    NSAppleEventManager* em = [NSAppleEventManager sharedAppleEventManager];
    [em removeEventHandlerForEventClass:KInternetEventClass andEventID:KAEGetURL];

    [Preferences setSpellCheckEnabled:[_fieldEditor isContinuousSpellCheckingEnabled]];
    [Preferences setGrammarCheckEnabled:[_fieldEditor isGrammarCheckingEnabled]];
    [Preferences setSmartInsertDeleteEnabled:[_fieldEditor smartInsertDeleteEnabled]];
    [Preferences setQuoteSubstitutionEnabled:[_fieldEditor isAutomaticQuoteSubstitutionEnabled]];
    [Preferences setLinkDetectionEnabled:[_fieldEditor isAutomaticLinkDetectionEnabled]];
    [Preferences setSpellingCorrectionEnabled:[_fieldEditor isAutomaticSpellingCorrectionEnabled]];
    [Preferences setDashSubstitutionEnabled:[_fieldEditor isAutomaticDashSubstitutionEnabled]];
    [Preferences setDataDetectionEnabled:[_fieldEditor isAutomaticDataDetectionEnabled]];
    [Preferences setTextReplacementEnabled:[_fieldEditor isAutomaticTextReplacementEnabled]];

    [_dcc terminate];
    [_world terminate];
    [_menu terminate];
    [ImageDownloadManager disposeInstance];
    [NSApp unregisterHotKey];
    [self saveWindowState];
}

#pragma mark - SUUpdater Delegate

- (void)updaterWillRelaunchApplication:(id)sender
{
    _terminating = YES;
}

#pragma mark - NSWorkspace Notifications

- (void)computerWillSleep:(NSNotification*)note
{
    [_world prepareForSleep];
}

- (void)computerDidWakeUp:(NSNotification*)note
{
    [_world autoConnect:YES];
}

- (void)computerWillPowerOff:(NSNotification*)note
{
    _terminating = YES;
    [NSApp terminate:nil];
}

- (void)handleURLEvent:(NSAppleEventDescriptor*)event withReplyEvent:(NSAppleEventDescriptor*)replyEvent
{
    //NSString* url = [[event descriptorAtIndex:1] stringValue];
    //LOG(@"%@", url);
}

#pragma mark - NSWindow Delegate

- (id)windowWillReturnFieldEditor:(NSWindow *)sender toObject:(id)client
{
    if (client == _text) {
        return _fieldEditor;
    }
    else {
        return nil;
    }
}

- (BOOL)windowShouldClose:(id)sender
{
    return [self queryTerminate];
}

- (void)windowWillClose:(NSNotification *)note
{
    _terminating = YES;
    [NSApp terminate:nil];
}

#pragma mark - FieldEditorTextView Delegate

- (BOOL)fieldEditorTextViewPaste:(id)sender;
{
    NSString* s = [[NSPasteboard generalPasteboard] stringContent];
    if (!s.length) return NO;

    IRCClient* client = _world.selectedClient;
    IRCChannel* channel = _world.selectedChannel;
    if (channel) {
        static NSRegularExpression* regex = nil;
        if (!regex) {
            NSString* pattern = @"(\r\n|\r|\n)[^\r\n]";
            regex = [[NSRegularExpression alloc] initWithPattern:pattern options:0 error:NULL];
        }

        NSRange range = [regex rangeOfFirstMatchInString:s options:0 range:NSMakeRange(0, s.length)];
        if (range.location != NSNotFound) {
            // multi line
            [_menu startPasteSheetWithContent:s nick:client.myNick uid:client.uid cid:channel.uid editMode:YES];
            return YES;
        }
    }

    if (![[_window firstResponder] isKindOfClass:[NSTextView class]]) {
        [_world focusInputText];
    }
    return NO;
}

#pragma mark - Utilities

- (void)sendText:(NSString*)command
{
    NSString* s = [_text stringValue];
    if (s.length) {
        if ([_world inputText:s command:command]) {
            [_inputHistory add:s];
            [_text setStringValue:@""];
        }
    }

    [_text focus];

    if (_completionStatus) {
        [_completionStatus clear];
    }
}

- (void)textEntered:(id)sender
{
    [self sendText:PRIVMSG];
}

- (void)set3columnLayout:(BOOL)value
{
    if (value == _threeColumns) return;
    _threeColumns = value;

    if (_threeColumns) {
        _infoSplitter.hidden = YES;
        _infoSplitter.inverted = YES;
        [_leftTreeBase addSubview:_treeScrollView];
        _treeSplitter.hidden = NO;
        if (_treeSplitter.position < 1) _treeSplitter.position = 120;
        _treeScrollView.frame = _leftTreeBase.bounds;
    }
    else {
        _treeSplitter.hidden = YES;
        [_rightTreeBase addSubview:_treeScrollView];
        _infoSplitter.inverted = NO;
        _infoSplitter.hidden = NO;
        if (_infoSplitter.position < 1) _infoSplitter.position = 100;
        _treeScrollView.frame = _rightTreeBase.bounds;
    }
}

#pragma mark - Preferences

- (void)loadWindowState
{
    NSDictionary* dic = [Preferences loadWindowStateWithName:@"main_window"];

    if (dic) {
        int x = [dic intForKey:@"x"];
        int y = [dic intForKey:@"y"];
        int w = [dic intForKey:@"w"];
        int h = [dic intForKey:@"h"];
        id spellCheckingValue = [dic objectForKey:@"spell_checking"];

        [_window setFrame:NSMakeRect(x, y, w, h) display:YES];
        _rootSplitter.position = [dic intForKey:@"root"];
        _logSplitter.position = [dic intForKey:@"log"];
        _infoSplitter.position = [dic intForKey:@"info"];
        _treeSplitter.position = [dic intForKey:@"tree"];

        if (spellCheckingValue) {
            [_fieldEditor setContinuousSpellCheckingEnabled:[spellCheckingValue boolValue]];
        }
    }
    else {
        NSScreen* screen = [NSScreen mainScreen];
        if (screen) {
            NSRect rect = [screen visibleFrame];
            NSPoint p = NSMakePoint(rect.origin.x + rect.size.width/2, rect.origin.y + rect.size.height/2);
            int w = 500;
            int h = 500;
            rect = NSMakeRect(p.x - w/2, p.y - h/2, w, h);
            [_window setFrame:rect display:YES];
        }

        _rootSplitter.position = 130;
        _logSplitter.position = 150;
        _infoSplitter.position = 250;
        _treeSplitter.position = 120;
    }
}

- (void)saveWindowState
{
    NSMutableDictionary* dic = [NSMutableDictionary dictionary];

    NSRect rect = _window.frame;
    [dic setInt:rect.origin.x forKey:@"x"];
    [dic setInt:rect.origin.y forKey:@"y"];
    [dic setInt:rect.size.width forKey:@"w"];
    [dic setInt:rect.size.height forKey:@"h"];
    [dic setInt:_rootSplitter.position forKey:@"root"];
    [dic setInt:_logSplitter.position forKey:@"log"];
    [dic setInt:_infoSplitter.position forKey:@"info"];
    [dic setInt:_treeSplitter.position forKey:@"tree"];
    [dic setBool:[_fieldEditor isContinuousSpellCheckingEnabled] forKey:@"spell_checking"];

    [Preferences saveWindowState:dic name:@"main_window"];
    [Preferences sync];
}

- (void)themeDidChange:(NSNotification*)note
{
    [_world reloadTheme];
    [self set3columnLayout:[Preferences mainWindowLayout] == MAIN_WINDOW_LAYOUT_3_COLUMN];
    [_window setAlphaValue:[Preferences themeTransparency]];
}

#pragma mark - Nick Completion

- (void)completeNick:(BOOL)forward
{
    IRCClient* client = _world.selectedClient;
    IRCChannel* channel = _world.selectedChannel;
    if (!client || !channel) return;

    if ([_window firstResponder] != [_window fieldEditor:NO forObject:_text]) {
        [_world focusInputText];
    }

    NSText* fe = [_window fieldEditor:YES forObject:_text];
    if (!fe) return;

    NSRange selectedRange = [fe selectedRange];
    if (selectedRange.location == NSNotFound) return;

    if (!_completionStatus) {
        _completionStatus = [NickCompletinStatus new];
    }

    NickCompletinStatus* status = _completionStatus;
    NSString* s = _text.stringValue;

    if ([status.text isEqualToString:s]
        && status.range.location != NSNotFound
        && NSMaxRange(status.range) == selectedRange.location
        && selectedRange.length == 0) {
        selectedRange = status.range;
    }

    // pre is the left part of the cursor
    // sel is the left part of the cursor

    BOOL head = YES;
    NSString* pre = [s substringToIndex:selectedRange.location];
    NSString* sel = [s substringWithRange:selectedRange];

    for (int i=pre.length-1; i>=0; --i) {
        UniChar c = [pre characterAtIndex:i];
        if (c != ' ') {
            ;
        }
        else {
            ++i;
            if (i == pre.length) return;
            head = NO;
            pre = [pre substringFromIndex:i];
            break;
        }
    }

    BOOL commandMode = NO;
    BOOL twitterMode = NO;

    if (pre.length) {
        UniChar c = [pre characterAtIndex:0];
        if (head && c == '/') {
            // command mode
            commandMode = YES;
            pre = [pre substringFromIndex:1];
            if (!pre.length) return;
        }
        else if (c == '@') {
            // workaround for @nick form
            twitterMode = YES;
            pre = [pre substringFromIndex:1];
            if (!pre.length) return;
        }
    }

    // prepare for matching

    NSString* current = [pre stringByAppendingString:sel];

    int len = current.length;
    for (int i=0; i<len; ++i) {
        UniChar c = [current characterAtIndex:i];
        if (c != ' ' && c != ':') {
            ;
        }
        else {
            current = [current substringToIndex:i];
            break;
        }
    }

    if (!current.length && (commandMode || twitterMode)) return;

    // sort the choices

    NSString* lowerPre = [pre lowercaseString];
    NSString* lowerCurrent = [current lowercaseString];

    NSArray* lowerChoices;
    NSArray* choices;

    CGFloat firstUserWeight = 0;

    if (commandMode) {
        choices = [NSArray arrayWithObjects:
                   @"action", @"away", @"ban", @"clear", @"close",
                   @"ctcp", @"ctcpreply", @"cycle", @"dehalfop", @"deop",
                   @"devoice", @"halfop", @"hop", @"ignore", @"invite",
                   @"ison", @"join", @"kick", @"leave", @"list",
                   @"me", @"mode", @"msg", @"nick", @"notice",
                   @"op", @"part", @"pong", @"privmsg", @"query",
                   @"quit", @"quote", @"raw", @"rejoin", @"timer",
                   @"topic", @"umode", @"unban", @"unignore", @"voice",
                   @"weights", @"who", @"whois", @"whowas",
                   nil];
        lowerChoices = choices;
    }
    else {
        NSMutableArray* users = [channel.members mutableCopy];
        [users sortUsingSelector:@selector(compareUsingWeights:)];

        NSMutableArray* nicks = [NSMutableArray array];
        NSMutableArray* lowerNicks = [NSMutableArray array];

        BOOL seenFirstUser = NO;
        for (IRCUser* m in users) {
            if (!m.isMyself) {
                if (!seenFirstUser) {
                    seenFirstUser = YES;
                    firstUserWeight = m.weight;
                }
                [nicks addObject:m.nick];
                [lowerNicks addObject:m.canonicalNick];
            }
        }

        choices = nicks;
        lowerChoices = lowerNicks;
    }

    NSMutableArray* currentChoices = [NSMutableArray array];
    NSMutableArray* currentLowerChoices = [NSMutableArray array];

    int i = 0;
    for (NSString* s in lowerChoices) {
        if ([s hasPrefix:lowerPre]) {
            [currentChoices addObject:[choices objectAtIndex:i]];
            [currentLowerChoices addObject:s];
        }
        ++i;
    }

    // If we're trying to complete a half-entered string, and we can't find a
    // choice with a common prefix, there is nothing more to be done.
    // Otherwise, pick the user with the highest weight.
    if (!currentChoices.count) {
        if (current.length) return;
        if (!commandMode && !twitterMode && firstUserWeight > 0) {
            NSString* firstChoice = [choices objectAtIndex:0];
            [currentChoices addObject:firstChoice];
            [currentLowerChoices addObject:[firstChoice lowercaseString]];
        }
    }

    if (!currentChoices.count) return;

    // find the next choice

    NSString* t;
    NSUInteger index = [currentLowerChoices indexOfObject:lowerCurrent];
    if (index != NSNotFound) {
        if (forward) {
            ++index;
            if (currentChoices.count <= index) {
                index = 0;
            }
        }
        else {
            if (index == 0) {
                index = currentChoices.count - 1;
            }
            else {
                --index;
            }
        }
        t = [currentChoices objectAtIndex:index];
    }
    else {
        t = [currentChoices objectAtIndex:0];
    }

    // add suffix

    if (commandMode) {
        t = [t stringByAppendingString:@" "];
    }
    else if (head) {
        if (twitterMode) {
            t = [t stringByAppendingString:@" "];
        }
        else {
            t = [t stringByAppendingString:@": "];
        }
    }

    // set completed item to the input text field

    NSRange r = selectedRange;
    r.location -= pre.length;
    r.length += pre.length;
    [fe replaceCharactersInRange:r withString:t];
    [fe scrollRangeToVisible:fe.selectedRange];
    r.location += t.length;
    r.length = 0;
    fe.selectedRange = r;

    if (currentChoices.count == 1) {
        [status clear];
    }
    else {
        selectedRange.length = t.length - pre.length;
        status.text = _text.stringValue;
        status.range = selectedRange;
    }
}

#pragma mark - Keyboard Navigation

typedef enum {
    SCROLL_TOP,
    SCROLL_BOTTOM,
    SCROLL_PAGE_UP,
    SCROLL_PAGE_DOWN,
} ScrollKind;

- (void)scroll:(ScrollKind)op
{
    IRCTreeItem* sel = _world.selected;
    if (sel) {
        LogController* log = [sel log];
        LogView* view = log.view;
        switch (op) {
            case SCROLL_TOP:
                [log moveToTop];
                break;
            case SCROLL_BOTTOM:
                [log moveToBottom];
                break;
            case SCROLL_PAGE_UP:
                [view scrollPageUp:nil];
                break;
            case SCROLL_PAGE_DOWN:
                [view scrollPageDown:nil];
                break;
        }
    }
}

- (void)inputScrollToTop:(NSEvent*)e
{
    [self scroll:SCROLL_TOP];
}

- (void)inputScrollToBottom:(NSEvent*)e
{
    [self scroll:SCROLL_BOTTOM];
}

- (void)inputScrollPageUp:(NSEvent*)e
{
    [self scroll:SCROLL_PAGE_UP];
}

- (void)inputScrollPageDown:(NSEvent*)e
{
    [self scroll:SCROLL_PAGE_DOWN];
}

typedef enum {
    MOVE_UP,
    MOVE_DOWN,
    MOVE_LEFT,
    MOVE_RIGHT,
    MOVE_ALL,
    MOVE_ACTIVE,
    MOVE_UNREAD,
} MoveKind;

- (void)move:(MoveKind)dir target:(MoveKind)target
{
    if (dir == MOVE_UP || dir == MOVE_DOWN) {
        id sel = _world.selected;
        if (!sel) return;
        int n = [_tree rowForItem:sel];
        if (n < 0) return;
        int start = n;
        int count = [_tree numberOfRows];
        if (count <= 1) return;
        while (1) {
            if (dir == MOVE_UP) {
                --n;
                if (n < 0) n = count - 1;
            }
            else {
                ++n;
                if (count <= n) n = 0;
            }

            if (n == start) break;

            id i = [_tree itemAtRow:n];
            if (i) {
                if (target == MOVE_ACTIVE) {
                    if (![i isClient] && [i isActive]) {
                        [_world select:i];
                        break;
                    }
                }
                else if (target == MOVE_UNREAD) {
                    if ([i isUnread]) {
                        [_world select:i];
                        break;
                    }
                }
                else {
                    [_world select:i];
                    break;
                }
            }
        }
    }
    else if (dir == MOVE_LEFT || dir == MOVE_RIGHT) {
        IRCClient* client = _world.selectedClient;
        if (!client) return;
        NSUInteger pos = [_world.clients indexOfObjectIdenticalTo:client];
        if (pos == NSNotFound) return;
        int n = pos;
        int start = n;
        int count = _world.clients.count;
        if (count <= 1) return;
        while (1) {
            if (dir == MOVE_LEFT) {
                --n;
                if (n < 0) n = count - 1;
            }
            else {
                ++n;
                if (count <= n) n = 0;
            }

            if (n == start) break;

            client = [_world.clients objectAtIndex:n];
            if (client) {
                if (target == MOVE_ACTIVE) {
                    if (client.isLoggedIn) {
                        id t = client.lastSelectedChannel ?: (id)client;
                        [_world select:t];
                        break;
                    }
                }
                else {
                    id t = client.lastSelectedChannel ?: (id)client;
                    [_world select:t];
                    break;
                }
            }
        }
    }
}

- (void)selectPreviousChannel:(NSEvent*)e
{
    [self move:MOVE_UP target:MOVE_ALL];
}

- (void)selectNextChannel:(NSEvent*)e
{
    [self move:MOVE_DOWN target:MOVE_ALL];
}

- (void)selectPreviousUnreadChannel:(NSEvent*)e
{
    [self move:MOVE_UP target:MOVE_UNREAD];
}

- (void)selectNextUnreadChannel:(NSEvent*)e
{
    [self move:MOVE_DOWN target:MOVE_UNREAD];
}

- (void)selectPreviousActiveChannel:(NSEvent*)e
{
    [self move:MOVE_UP target:MOVE_ACTIVE];
}

- (void)selectNextActiveChannel:(NSEvent*)e
{
    [self move:MOVE_DOWN target:MOVE_ACTIVE];
}

- (void)selectPreviousServer:(NSEvent*)e
{
    [self move:MOVE_LEFT target:MOVE_ALL];
}

- (void)selectNextServer:(NSEvent*)e
{
    [self move:MOVE_RIGHT target:MOVE_ALL];
}

- (void)selectPreviousActiveServer:(NSEvent*)e
{
    [self move:MOVE_LEFT target:MOVE_ACTIVE];
}

- (void)selectNextActiveServer:(NSEvent*)e
{
    [self move:MOVE_RIGHT target:MOVE_ACTIVE];
}

- (void)selectPreviousSelection:(NSEvent*)e
{
    [_world selectPreviousItem];
}

- (void)selectChannelAtNumber:(NSEvent*)e
{
    NSString* s = [e charactersIgnoringModifiers];
    if (s.length) {
        UniChar c = [s characterAtIndex:0];
        int n = c - '0';
        [_world selectChannelAt:n];
    }
}

- (void)selectServerAtNumber:(NSEvent*)e
{
    NSString* s = [e charactersIgnoringModifiers];
    if (s.length) {
        UniChar c = [s characterAtIndex:0];
        int n = c - '0';
        n = (n == 0) ? 9 : (n - 1);
        [_world selectClientAt:n];
    }
}

- (void)tab:(NSEvent*)e
{
    switch ([Preferences tabAction]) {
        case TAB_COMPLETE_NICK:
            [self completeNick:YES];
            break;
        case TAB_UNREAD:
            [self move:MOVE_DOWN target:MOVE_UNREAD];
            break;
        default:
            break;
    }
}

- (void)shiftTab:(NSEvent*)e
{
    switch ([Preferences tabAction]) {
        case TAB_COMPLETE_NICK:
            [self completeNick:NO];
            break;
        case TAB_UNREAD:
            [self move:MOVE_UP target:MOVE_UNREAD];
            break;
        default:
            break;
    }
}

- (void)sendNotice:(NSEvent*)e
{
    [self sendText:NOTICE];
}

- (void)showPasteDialog:(NSEvent*)e
{
    [_menu onPasteDialog:nil];
}

- (void)inputHistoryUp:(NSEvent*)e
{
    NSString* s = [_inputHistory up:[_text stringValue]];
    if (s) {
        [_text setStringValue:s];
        [_world focusInputText];
    }
}

- (void)inputHistoryDown:(NSEvent*)e
{
    NSString* s = [_inputHistory down:[_text stringValue]];
    if (s) {
        [_text setStringValue:s];
        [_world focusInputText];
    }
}

- (void)handler:(SEL)sel code:(int)keyCode mods:(NSUInteger)mods
{
    [_window registerKeyHandler:sel key:keyCode modifiers:mods];
}

- (void)handler:(SEL)sel char:(UniChar)c mods:(NSUInteger)mods
{
    [_window registerKeyHandler:sel character:c modifiers:mods];
}

- (void)inputHandler:(SEL)sel code:(int)keyCode mods:(NSUInteger)mods
{
    [_fieldEditor registerKeyHandler:sel key:keyCode modifiers:mods];
}

- (void)registerKeyHandlers
{
    [_window setKeyHandlerTarget:self];
    [_fieldEditor setKeyHandlerTarget:self];

    [self handler:@selector(tab:) code:KEY_TAB mods:0];
    [self handler:@selector(shiftTab:) code:KEY_TAB mods:NSShiftKeyMask];
    [self handler:@selector(sendNotice:) code:KEY_ENTER mods:NSControlKeyMask];
    [self handler:@selector(sendNotice:) code:KEY_RETURN mods:NSControlKeyMask];
    [self handler:@selector(showPasteDialog:) code:KEY_ENTER mods:NSAlternateKeyMask];
    [self handler:@selector(showPasteDialog:) code:KEY_RETURN mods:NSAlternateKeyMask];
    [self handler:@selector(selectPreviousActiveChannel:) char:'[' mods:NSCommandKeyMask];
    [self handler:@selector(selectNextActiveChannel:) char:']' mods:NSCommandKeyMask];
    [self handler:@selector(selectPreviousActiveChannel:) char:'{' mods:NSCommandKeyMask|NSShiftKeyMask];
    [self handler:@selector(selectNextActiveChannel:) char:'}' mods:NSCommandKeyMask|NSShiftKeyMask];
    [self handler:@selector(selectPreviousChannel:) code:KEY_UP mods:NSControlKeyMask];
    [self handler:@selector(selectNextChannel:) code:KEY_DOWN mods:NSControlKeyMask];
    [self handler:@selector(selectPreviousServer:) code:KEY_LEFT mods:NSControlKeyMask];
    [self handler:@selector(selectNextServer:) code:KEY_RIGHT mods:NSControlKeyMask];
    [self handler:@selector(selectPreviousActiveChannel:) code:KEY_UP mods:NSCommandKeyMask];
    [self handler:@selector(selectPreviousActiveChannel:) code:KEY_UP mods:NSCommandKeyMask|NSAlternateKeyMask];
    [self handler:@selector(selectNextActiveChannel:) code:KEY_DOWN mods:NSCommandKeyMask];
    [self handler:@selector(selectNextActiveChannel:) code:KEY_DOWN mods:NSCommandKeyMask|NSAlternateKeyMask];
    [self handler:@selector(selectPreviousActiveServer:) code:KEY_LEFT mods:NSCommandKeyMask|NSAlternateKeyMask];
    [self handler:@selector(selectNextActiveServer:) code:KEY_RIGHT mods:NSCommandKeyMask|NSAlternateKeyMask];
    [self handler:@selector(selectNextUnreadChannel:) code:KEY_TAB mods:NSControlKeyMask];
    [self handler:@selector(selectNextUnreadChannel:) code:KEY_DOWN mods:NSCommandKeyMask|NSAlternateKeyMask];
    [self handler:@selector(selectPreviousUnreadChannel:) code:KEY_TAB mods:NSControlKeyMask|NSShiftKeyMask];
    [self handler:@selector(selectPreviousUnreadChannel:) code:KEY_UP mods:NSCommandKeyMask|NSAlternateKeyMask];
    [self handler:@selector(selectNextUnreadChannel:) code:KEY_SPACE mods:NSAlternateKeyMask];
    [self handler:@selector(selectPreviousUnreadChannel:) code:KEY_SPACE mods:NSAlternateKeyMask|NSShiftKeyMask];
    [self handler:@selector(selectPreviousSelection:) code:KEY_TAB mods:NSAlternateKeyMask];

    for (int i=0; i<=9; ++i) {
        [self handler:@selector(selectChannelAtNumber:) char:'0'+i mods:NSCommandKeyMask];
    }
    for (int i=0; i<=9; ++i) {
        [self handler:@selector(selectServerAtNumber:) char:'0'+i mods:NSCommandKeyMask|NSControlKeyMask];
    }

    [self inputHandler:@selector(inputScrollToTop:) code:KEY_HOME mods:0];
    [self inputHandler:@selector(inputScrollToBottom:) code:KEY_END mods:0];
    [self inputHandler:@selector(inputScrollPageUp:) code:KEY_PAGE_UP mods:0];
    [self inputHandler:@selector(inputScrollPageDown:) code:KEY_PAGE_DOWN mods:0];
    [self inputHandler:@selector(inputHistoryUp:) code:KEY_UP mods:0];
    [self inputHandler:@selector(inputHistoryUp:) code:KEY_UP mods:NSAlternateKeyMask];
    [self inputHandler:@selector(inputHistoryDown:) code:KEY_DOWN mods:0];
    [self inputHandler:@selector(inputHistoryDown:) code:KEY_DOWN mods:NSAlternateKeyMask];
}

#pragma mark - WelcomeDialog Delegate

- (void)welcomeDialog:(WelcomeDialog*)sender onOK:(NSDictionary*)config
{
    NSString* host = [config objectForKey:@"host"];
    NSString* name = host;

    NSString* hostPattern = @"^[^\\s]+\\s+\\(([^()]+)\\)";
    NSRegularExpression* hostRegex = [[NSRegularExpression alloc] initWithPattern:hostPattern options:0 error:NULL];
    NSTextCheckingResult* result = [hostRegex firstMatchInString:host options:0 range:NSMakeRange(0, host.length)];
    if (result && result.numberOfRanges > 0) {
        name = [host substringWithRange:[result rangeAtIndex:1]];
    }

    NSString* nick = [config objectForKey:@"nick"];
    NSString* user = [[nick lowercaseString] safeUsername];
    NSString* realName = nick;

    NSMutableArray* channels = [NSMutableArray array];
    for (NSString* s in [config objectForKey:@"channels"]) {
        [channels addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                             s, @"name",
                             @YES, @"auto_join",
                             @YES, @"console",
                             @YES, @"notify",
                             @"+sn", @"mode",
                             nil]];
    }

    NSMutableDictionary* dic = [NSMutableDictionary dictionary];
    [dic setObject:host forKey:@"host"];
    [dic setObject:name forKey:@"name"];
    [dic setObject:nick forKey:@"nick"];
    [dic setObject:user forKey:@"username"];
    [dic setObject:realName forKey:@"realname"];
    [dic setObject:channels forKey:@"channels"];
    [dic setObject:[config objectForKey:@"autoConnect"] forKey:@"auto_connect"];

    if ([NSLocale prefersJapaneseLanguage]) {
        NSString* net = [host lowercaseString];
        if ([net contains:@"freenode"]
            || [net contains:@"undernet"]
            || [net contains:@"quakenet"]
            || [net contains:@"mozilla"]
            || [net contains:@"ustream"]) {
            [dic setObject:@(NSUTF8StringEncoding) forKey:@"encoding"];
        }
        else {
            [dic setObject:@(NSISO2022JPStringEncoding) forKey:@"encoding"];
        }
    }

    IRCClientConfig* c = [[IRCClientConfig alloc] initWithDictionary:dic];
    IRCClient* u = [_world createClient:c reload:YES];
    [_world save];

    if (c.autoConnect) {
        [u connect];
    }
}

- (void)welcomeDialogWillClose:(WelcomeDialog*)sender
{
    _welcomeDialog = nil;

    [_window makeKeyAndOrderFront:nil];
}

@end
