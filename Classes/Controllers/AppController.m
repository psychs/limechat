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
#import "OnigRegexp.h"
#import "NSPasteboardHelper.h"
#import "NSStringHelper.h"
#import "NSDictionaryHelper.h"
#import "NSLocaleHelper.h"


#define KInternetEventClass	1196773964
#define KAEGetURL			1196773964


@interface NSTextView (NSTextViewCompatibility)
- (void)setAutomaticSpellingCorrectionEnabled:(BOOL)v;
- (BOOL)isAutomaticSpellingCorrectionEnabled;
- (void)setAutomaticDashSubstitutionEnabled:(BOOL)v;
- (BOOL)isAutomaticDashSubstitutionEnabled;
- (void)setAutomaticDataDetectionEnabled:(BOOL)v;
- (BOOL)isAutomaticDataDetectionEnabled;
- (void)setAutomaticTextReplacementEnabled:(BOOL)v;
- (BOOL)isAutomaticTextReplacementEnabled;
@end


@interface AppController (Private)
- (void)set3columnLayout:(BOOL)value;
- (void)loadWindowState;
- (void)saveWindowState;
- (void)registerKeyHandlers;
- (void)prelude;
@end


@implementation AppController

- (void)dealloc
{
	[welcomeDialog release];
	[growl release];
	[dcc release];
	[fieldEditor release];
	[world release];
	[viewTheme release];
	[inputHistory release];
	[completionStatus release];
	[super dealloc];
}

#pragma mark -
#pragma mark NSApplication Delegate

- (void)awakeFromNib
{
	SInt32 version = 0;
	Gestalt(gestaltSystemVersion, &version);
	if (version >= 0x1070) {
		if ([window respondsToSelector:@selector(setCollectionBehavior:)]) {
			const int LCNSWindowCollectionBehaviorFullScreenPrimary = 1 << 7;
			NSWindowCollectionBehavior behavior = [window collectionBehavior];
			behavior |= LCNSWindowCollectionBehaviorFullScreenPrimary;
			[window setCollectionBehavior:behavior];
		}
	}
	
	[self prelude];

	[Preferences initPreferences];

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
	
	rootSplitter.fixedViewIndex = 1;
	logSplitter.fixedViewIndex = 1;
	infoSplitter.fixedViewIndex = 1;
	treeSplitter.hidden = YES;
	
	fieldEditor = [[FieldEditorTextView alloc] initWithFrame:NSZeroRect];
	[fieldEditor setFieldEditor:YES];
	fieldEditor.pasteDelegate = self;

	[fieldEditor setContinuousSpellCheckingEnabled:[Preferences spellCheckEnabled]];
	[fieldEditor setGrammarCheckingEnabled:[Preferences grammarCheckEnabled]];
	[fieldEditor setSmartInsertDeleteEnabled:[Preferences smartInsertDeleteEnabled]];
	[fieldEditor setAutomaticQuoteSubstitutionEnabled:[Preferences quoteSubstitutionEnabled]];
	[fieldEditor setAutomaticLinkDetectionEnabled:[Preferences linkDetectionEnabled]];
	if ([fieldEditor respondsToSelector:@selector(setAutomaticSpellingCorrectionEnabled:)]) {
		[fieldEditor setAutomaticSpellingCorrectionEnabled:[Preferences spellingCorrectionEnabled]];
	}
	if ([fieldEditor respondsToSelector:@selector(setAutomaticDashSubstitutionEnabled:)]) {
		[fieldEditor setAutomaticDashSubstitutionEnabled:[Preferences dashSubstitutionEnabled]];
	}
	if ([fieldEditor respondsToSelector:@selector(setAutomaticDataDetectionEnabled:)]) {
		[fieldEditor setAutomaticDataDetectionEnabled:[Preferences dataDetectionEnabled]];
	}
	if ([fieldEditor respondsToSelector:@selector(setAutomaticTextReplacementEnabled:)]) {
		[fieldEditor setAutomaticTextReplacementEnabled:[Preferences textReplacementEnabled]];
	}
	
	[text setFocusRingType:NSFocusRingTypeNone];
	
	viewTheme = [ViewTheme new];
	viewTheme.name = [Preferences themeName];
	tree.theme = viewTheme.other;
	memberList.theme = viewTheme.other;
	MemberListViewCell* cell = [[MemberListViewCell new] autorelease];
	[cell setup:viewTheme.other];
	[[[memberList tableColumns] objectAtIndex:0] setDataCell:cell];
	
	[self loadWindowState];
	[window setAlphaValue:[Preferences themeTransparency]];
	[self set3columnLayout:[Preferences mainWindowLayout] == MAIN_WINDOW_LAYOUT_3_COLUMN];
	
	IRCWorldConfig* seed = [[[IRCWorldConfig alloc] initWithDictionary:[Preferences loadWorld]] autorelease];
	
	world = [IRCWorld new];
	world.app = self;
	world.window = window;
	world.growl = growl;
	world.tree = tree;
	world.text = text;
	world.logBase = logBase;
	world.consoleBase = consoleBase;
	world.chatBox = chatBox;
	world.fieldEditor = fieldEditor;
	world.memberList = memberList;
	[world setServerMenuItem:serverMenu];
	[world setChannelMenuItem:channelMenu];
	world.treeMenu = treeMenu;
	world.logMenu = logMenu;
	world.consoleMenu = consoleMenu;
	world.urlMenu = urlMenu;
	world.addrMenu = addrMenu;
	world.chanMenu = chanMenu;
	world.memberMenu = memberMenu;
	world.viewTheme = viewTheme;
	world.menuController = menu;
	[world setup:seed];

	tree.dataSource = world;
	tree.delegate = world;
	tree.responderDelegate = world;
	[tree reloadData];
	[world setupTree];
	
	menu.app = self;
	menu.world = world;
	menu.window = window;
	menu.tree = tree;
	menu.memberList = memberList;
	menu.text = text;
	[menu setUp];
	
	memberList.target = menu;
	[memberList setDoubleAction:@selector(memberListDoubleClicked:)];
	memberList.keyDelegate = world;
	memberList.dropDelegate = world;
	
	dcc = [DCCController new];
	dcc.world = world;
	dcc.mainWindow = window;
	world.dcc = dcc;
	
	growl = [GrowlController new];
	growl.owner = world;
	world.growl = growl;
	[growl registerToGrowl];
	
	inputHistory = [InputHistory new];

	[ImageDownloadManager instance].world = world;

	[self registerKeyHandlers];
}

- (void)applicationDidFinishLaunching:(NSNotification *)note
{
	[ViewTheme createUserDirectory];
	
	if (!world.clients.count) {
		welcomeDialog = [WelcomeDialog new];
		welcomeDialog.delegate = self;
		[welcomeDialog show];
	}
	else {
		[window makeFirstResponder:text];
		[window makeKeyAndOrderFront:nil];
		[world autoConnect:NO];
	}
}

- (void)applicationDidBecomeActive:(NSNotification *)note
{
	id sel = world.selected;
	if (sel) {
		[sel resetState];
		[world updateIcon];
	}
	
	[tree setNeedsDisplay];
}

- (void)applicationDidResignActive:(NSNotification *)note
{
	[tree setNeedsDisplay];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication*)sender hasVisibleWindows:(BOOL)flag
{
	[window makeKeyAndOrderFront:nil];
	return YES;
}

- (void)applicationDidReceiveHotKey:(id)sender
{
	if (![window isVisible] || ![NSApp isActive]) {
		[NSApp activateIgnoringOtherApps:YES];
		[window makeKeyAndOrderFront:nil];
		[text focus];
	}
	else {
		[NSApp hide:nil];
	}
}

- (BOOL)queryTerminate
{
	if (terminating) {
		return YES;
	}
	
	int receiving = [dcc countReceivingItems];
	int sending = [dcc countSendingItems];
	
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
	
	[Preferences setSpellCheckEnabled:[fieldEditor isContinuousSpellCheckingEnabled]];
	[Preferences setGrammarCheckEnabled:[fieldEditor isGrammarCheckingEnabled]];
	[Preferences setSmartInsertDeleteEnabled:[fieldEditor smartInsertDeleteEnabled]];
	[Preferences setQuoteSubstitutionEnabled:[fieldEditor isAutomaticQuoteSubstitutionEnabled]];
	[Preferences setLinkDetectionEnabled:[fieldEditor isAutomaticLinkDetectionEnabled]];
	
	if ([fieldEditor respondsToSelector:@selector(isAutomaticSpellingCorrectionEnabled)]) {
		[Preferences setSpellingCorrectionEnabled:[fieldEditor isAutomaticSpellingCorrectionEnabled]];
	}
	if ([fieldEditor respondsToSelector:@selector(isAutomaticDashSubstitutionEnabled)]) {
		[Preferences setDashSubstitutionEnabled:[fieldEditor isAutomaticDashSubstitutionEnabled]];
	}
	if ([fieldEditor respondsToSelector:@selector(isAutomaticDataDetectionEnabled)]) {
		[Preferences setDataDetectionEnabled:[fieldEditor isAutomaticDataDetectionEnabled]];
	}
	if ([fieldEditor respondsToSelector:@selector(isAutomaticSpellingCorrectionEnabled)]) {
		[Preferences setTextReplacementEnabled:[fieldEditor isAutomaticTextReplacementEnabled]];
	}
	
	[dcc terminate];
	[world terminate];
	[menu terminate];
	[ImageDownloadManager disposeInstance];
	[NSApp unregisterHotKey];
	[self saveWindowState];
}

#pragma mark -
#pragma mark SUUpdater Delegate

- (void)updaterWillRelaunchApplication:(id)sender
{
	terminating = YES;
}

#pragma mark -
#pragma mark NSWorkspace Notifications

- (void)computerWillSleep:(NSNotification*)note
{
	[world prepareForSleep];
}

- (void)computerDidWakeUp:(NSNotification*)note
{
	[world autoConnect:YES];
}

- (void)computerWillPowerOff:(NSNotification*)note
{
	terminating = YES;
	[NSApp terminate:nil];
}

- (void)handleURLEvent:(NSAppleEventDescriptor*)event withReplyEvent:(NSAppleEventDescriptor*)replyEvent
{
	//NSString* url = [[event descriptorAtIndex:1] stringValue];
	//LOG(@"%@", url);
}

#pragma mark -
#pragma mark NSWindow Delegate

- (id)windowWillReturnFieldEditor:(NSWindow *)sender toObject:(id)client
{
	if (client == text) {
		return fieldEditor;
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
	terminating = YES;
	[NSApp terminate:nil];
}

#pragma mark -
#pragma mark FieldEditorTextView Delegate

- (BOOL)fieldEditorTextViewPaste:(id)sender;
{
	NSString* s = [[NSPasteboard generalPasteboard] stringContent];
	if (!s.length) return NO;
	
	IRCClient* client = world.selectedClient;
	IRCChannel* channel = world.selectedChannel;
	if (channel) {
		static OnigRegexp* regex = nil;
		if (!regex) {
			NSString* pattern = @"(\r\n|\r|\n)[^\r\n]";
			regex = [[OnigRegexp compile:pattern] retain];
		}
		
		OnigResult* result = [regex search:s];
		if (result) {
			// multi line
			[menu startPasteSheetWithContent:s nick:client.myNick uid:client.uid cid:channel.uid editMode:YES];
			return YES;
		}
	}
	
	if (![[window firstResponder] isKindOfClass:[NSTextView class]]) {
		[world focusInputText];
	}
	return NO;
}

#pragma mark -
#pragma mark Utilities

- (void)sendText:(NSString*)command
{
	NSString* s = [text stringValue];
	if (s.length) {
		if ([world inputText:s command:command]) {
			[inputHistory add:s];
			[text setStringValue:@""];
		}
	}
	
	[text focus];
	
	if (completionStatus) {
		[completionStatus clear];
	}
}

- (void)textEntered:(id)sender
{
	[self sendText:PRIVMSG];
}

- (void)set3columnLayout:(BOOL)value
{
	if (value == threeColumns) return;
	threeColumns = value;
	
	if (threeColumns) {
		infoSplitter.hidden = YES;
		infoSplitter.inverted = YES;
		[leftTreeBase addSubview:treeScrollView];
		treeSplitter.hidden = NO;
		if (treeSplitter.position < 1) treeSplitter.position = 120;
		treeScrollView.frame = leftTreeBase.bounds;
	}
	else {
		treeSplitter.hidden = YES;
		[rightTreeBase addSubview:treeScrollView];
		infoSplitter.inverted = NO;
		infoSplitter.hidden = NO;
		if (infoSplitter.position < 1) infoSplitter.position = 100;
		treeScrollView.frame = rightTreeBase.bounds;
	}
}

#pragma mark -
#pragma mark Preferences

- (void)loadWindowState
{
	NSDictionary* dic = [Preferences loadWindowStateWithName:@"main_window"];
	
	if (dic) {
		int x = [dic intForKey:@"x"];
		int y = [dic intForKey:@"y"];
		int w = [dic intForKey:@"w"];
		int h = [dic intForKey:@"h"];
		id spellCheckingValue = [dic objectForKey:@"spell_checking"];
		
		[window setFrame:NSMakeRect(x, y, w, h) display:YES];
		rootSplitter.position = [dic intForKey:@"root"];
		logSplitter.position = [dic intForKey:@"log"];
		infoSplitter.position = [dic intForKey:@"info"];
		treeSplitter.position = [dic intForKey:@"tree"];
		
		if (spellCheckingValue) {
			[fieldEditor setContinuousSpellCheckingEnabled:[spellCheckingValue boolValue]];
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
			[window setFrame:rect display:YES];
		}
		
		rootSplitter.position = 130;
		logSplitter.position = 150;
		infoSplitter.position = 250;
		treeSplitter.position = 120;
	}
}

- (void)saveWindowState
{
	NSMutableDictionary* dic = [NSMutableDictionary dictionary];
	
	NSRect rect = window.frame;
	[dic setInt:rect.origin.x forKey:@"x"];
	[dic setInt:rect.origin.y forKey:@"y"];
	[dic setInt:rect.size.width forKey:@"w"];
	[dic setInt:rect.size.height forKey:@"h"];
	[dic setInt:rootSplitter.position forKey:@"root"];
	[dic setInt:logSplitter.position forKey:@"log"];
	[dic setInt:infoSplitter.position forKey:@"info"];
	[dic setInt:treeSplitter.position forKey:@"tree"];
	[dic setBool:[fieldEditor isContinuousSpellCheckingEnabled] forKey:@"spell_checking"];
	
	[Preferences saveWindowState:dic name:@"main_window"];
	[Preferences sync];
}

- (void)themeDidChange:(NSNotification*)note
{
	[world reloadTheme];
	[self set3columnLayout:[Preferences mainWindowLayout] == MAIN_WINDOW_LAYOUT_3_COLUMN];
	[window setAlphaValue:[Preferences themeTransparency]];
}

#pragma mark -
#pragma mark Nick Completion

- (void)completeNick:(BOOL)forward
{
	IRCClient* client = world.selectedClient;
	IRCChannel* channel = world.selectedChannel;
	if (!client || !channel) return;
	
	if ([window firstResponder] != [window fieldEditor:NO forObject:text]) {
		[world focusInputText];
	}
	
	NSText* fe = [window fieldEditor:YES forObject:text];
	if (!fe) return;
	
	NSRange selectedRange = [fe selectedRange];
	if (selectedRange.location == NSNotFound) return;
	
	if (!completionStatus) {
		completionStatus = [NickCompletinStatus new];
	}
	
	NickCompletinStatus* status = completionStatus;
	NSString* s = text.stringValue;
	
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
		NSMutableArray* users = [[channel.members mutableCopy] autorelease];
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
		status.text = text.stringValue;
		status.range = selectedRange;
	}
}

#pragma mark -
#pragma mark Keyboard Navigation

typedef enum {
	SCROLL_TOP,
	SCROLL_BOTTOM,
	SCROLL_PAGE_UP,
	SCROLL_PAGE_DOWN,
} ScrollKind;

- (void)scroll:(ScrollKind)op
{
	IRCTreeItem* sel = world.selected;
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
		id sel = world.selected;
		if (!sel) return;
		int n = [tree rowForItem:sel];
		if (n < 0) return;
		int start = n;
		int count = [tree numberOfRows];
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
			
			id i = [tree itemAtRow:n];
			if (i) {
				if (target == MOVE_ACTIVE) {
					if (![i isClient] && [i isActive]) {
						[world select:i];
						break;
					}
				}
				else if (target == MOVE_UNREAD) {
					if ([i isUnread]) {
						[world select:i];
						break;
					}
				}
				else {
					[world select:i];
					break;
				}
			}
		}
	}
	else if (dir == MOVE_LEFT || dir == MOVE_RIGHT) {
		IRCClient* client = world.selectedClient;
		if (!client) return;
		NSUInteger pos = [world.clients indexOfObjectIdenticalTo:client];
		if (pos == NSNotFound) return;
		int n = pos;
		int start = n;
		int count = world.clients.count;
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
			
			client = [world.clients objectAtIndex:n];
			if (client) {
				if (target == MOVE_ACTIVE) {
					if (client.isLoggedIn) {
						id t = client.lastSelectedChannel ?: (id)client;
						[world select:t];
						break;
					}
				}
				else {
					id t = client.lastSelectedChannel ?: (id)client;
					[world select:t];
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
	[world selectPreviousItem];
}

- (void)selectChannelAtNumber:(NSEvent*)e
{
	NSString* s = [e charactersIgnoringModifiers];
	if (s.length) {
		UniChar c = [s characterAtIndex:0];
		int n = c - '0';
		[world selectChannelAt:n];
	}
}

- (void)selectServerAtNumber:(NSEvent*)e
{
	NSString* s = [e charactersIgnoringModifiers];
	if (s.length) {
		UniChar c = [s characterAtIndex:0];
		int n = c - '0';
		n = (n == 0) ? 9 : (n - 1);
		[world selectClientAt:n];
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
	}
}

- (void)sendNotice:(NSEvent*)e
{
	[self sendText:NOTICE];
}

- (void)showPasteDialog:(NSEvent*)e
{
	[menu onPasteDialog:nil];
}

- (void)inputHistoryUp:(NSEvent*)e
{
	NSString* s = [inputHistory up:[text stringValue]];
	if (s) {
		[text setStringValue:s];
		[world focusInputText];
	}
}

- (void)inputHistoryDown:(NSEvent*)e
{
	NSString* s = [inputHistory down:[text stringValue]];
	if (s) {
		[text setStringValue:s];
		[world focusInputText];
	}
}

- (void)handler:(SEL)sel code:(int)keyCode mods:(NSUInteger)mods
{
	[window registerKeyHandler:sel key:keyCode modifiers:mods];
}

- (void)handler:(SEL)sel char:(UniChar)c mods:(NSUInteger)mods
{
	[window registerKeyHandler:sel character:c modifiers:mods];
}

- (void)inputHandler:(SEL)sel code:(int)keyCode mods:(NSUInteger)mods
{
	[fieldEditor registerKeyHandler:sel key:keyCode modifiers:mods];
}

- (void)registerKeyHandlers
{
	[window setKeyHandlerTarget:self];
	[fieldEditor setKeyHandlerTarget:self];
	
	[self handler:@selector(tab:) code:KEY_TAB mods:0];
	[self handler:@selector(shiftTab:) code:KEY_TAB mods:NSShiftKeyMask];
	[self handler:@selector(sendNotice:) code:KEY_ENTER mods:NSControlKeyMask];
	[self handler:@selector(sendNotice:) code:KEY_RETURN mods:NSControlKeyMask];
	[self handler:@selector(showPasteDialog:) code:KEY_ENTER mods:NSAlternateKeyMask];
	[self handler:@selector(showPasteDialog:) code:KEY_RETURN mods:NSAlternateKeyMask];
	[self handler:@selector(selectPreviousActiveChannel:) char:'[' mods:NSCommandKeyMask];
	[self handler:@selector(selectNextActiveChannel:) char:']' mods:NSCommandKeyMask];
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
	[self handler:@selector(selectPreviousUnreadChannel:) code:KEY_TAB mods:NSControlKeyMask|NSShiftKeyMask];
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

#pragma mark -
#pragma mark Migration

- (void)prelude
{
	[Preferences migrate];
}

#pragma mark -
#pragma mark WelcomeDialog Delegate

- (void)welcomeDialog:(WelcomeDialog*)sender onOK:(NSDictionary*)config
{
	NSString* host = [config objectForKey:@"host"];
	NSString* name = host;
	
	OnigRegexp* hostRegex = [OnigRegexp compile:@"^[^\\s]+\\s+\\(([^()]+)\\)"];
	OnigResult* result = [hostRegex search:host];
	if (result) {
		name = [host substringWithRange:[result rangeAt:1]];
	}
	
	NSString* nick = [config objectForKey:@"nick"];
	NSString* user = [[nick lowercaseString] safeUsername];
	NSString* realName = nick;
	
	NSMutableArray* channels = [NSMutableArray array];
	for (NSString* s in [config objectForKey:@"channels"]) {
		[channels addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							 s, @"name",
							 [NSNumber numberWithBool:YES], @"auto_join",
							 [NSNumber numberWithBool:YES], @"console",
							 [NSNumber numberWithBool:YES], @"growl",
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
			[dic setObject:[NSNumber numberWithLong:NSUTF8StringEncoding] forKey:@"encoding"];
		}
		else {
			[dic setObject:[NSNumber numberWithLong:NSISO2022JPStringEncoding] forKey:@"encoding"];
		}
	}
	
	IRCClientConfig* c = [[[IRCClientConfig alloc] initWithDictionary:dic] autorelease];
	IRCClient* u = [world createClient:c reload:YES];
	[world save];
	
	if (c.autoConnect) {
		[u connect];
	}
}

- (void)welcomeDialogWillClose:(WelcomeDialog*)sender
{
	[welcomeDialog autorelease];
	welcomeDialog = nil;
	
	[window makeKeyAndOrderFront:nil];
}

@end
