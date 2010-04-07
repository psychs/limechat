#import "AppController.h"
#import "Preferences.h"
#import "IRCTreeItem.h"
#import "NSDictionaryHelper.h"
#import "IRC.h"
#import "IRCWorld.h"
#import "IRCClient.h"


#define KInternetEventClass	1196773964
#define KAEGetURL			1196773964


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
	[fieldEditor release];
	[world release];
	[inputHistory release];
	[super dealloc];
}

#pragma mark -
#pragma mark NSApplication Delegate

- (void)awakeFromNib
{
	[self prelude];
	
	// register URL handler
	NSAppleEventManager* em = [NSAppleEventManager sharedAppleEventManager];
	[em setEventHandler:self andSelector:@selector(handleURLEvent:withReplyEvent:) forEventClass:KInternetEventClass andEventID:KAEGetURL];
	
	// @@@ hotkey
	
	rootSplitter.fixedViewIndex = 1;
	logSplitter.fixedViewIndex = 1;
	infoSplitter.fixedViewIndex = 1;
	treeSplitter.hidden = YES;
	
	fieldEditor = [[FieldEditorTextView alloc] initWithFrame:NSZeroRect];
	[fieldEditor setFieldEditor:YES];
	fieldEditor.pasteDelegate = self;
	[fieldEditor setContinuousSpellCheckingEnabled:YES];
	
	[text setFocusRingType:NSFocusRingTypeNone];
	
	[self loadWindowState];
	[self set3columnLayout:NO];
	
	IRCWorldConfig* seed = [[[IRCWorldConfig alloc] initWithDictionary:[NewPreferences loadWorld]] autorelease];
	
	world = [IRCWorld new];
	world.app = self;
	world.window = window;
	world.tree = tree;
	world.text = text;
	world.logBase = logBase;
	world.consoleBase = consoleBase;
	world.chatBox = chatBox;
	world.fieldEditor = fieldEditor;
	world.memberList = memberList;
	world.serverMenu = serverMenu;
	world.channelMenu = channelMenu;
	world.treeMenu = treeMenu;
	world.logMenu = logMenu;
	world.consoleMenu = consoleMenu;
	world.addrMenu = addrMenu;
	world.chanMenu = chanMenu;
	world.memberMenu = memberMenu;
	world.viewTheme = nil;
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
	
	memberList.target = menu;
	[memberList setDoubleAction:@selector(memberListDoubleClicked:)];
	memberList.keyDelegate = world;
	memberList.dropDelegate = world;
	
	//@@@ dcc manager
	
	inputHistory = [InputHistory new];
	
	NSNotificationCenter* nc = [[NSWorkspace sharedWorkspace] notificationCenter];
	[nc addObserver:self selector:@selector(computerWillSleep:) name:NSWorkspaceWillSleepNotification object:nil];
	[nc addObserver:self selector:@selector(computerDidWakeUp:) name:NSWorkspaceDidWakeNotification object:nil];
	[nc addObserver:self selector:@selector(computerWillPowerOff:) name:NSWorkspaceWillPowerOffNotification object:nil];
	
	[self registerKeyHandlers];
}

- (void)applicationDidFinishLaunching:(NSNotification *)note
{
	[window makeFirstResponder:text];
	[window makeKeyAndOrderFront:nil];
	[world autoConnect];
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

- (void)applicationDidReceiveHotKey:(id)sender
{
	if ([window isVisible] || ![NSApp isActive]) {
		[NSApp activateIgnoringOtherApps:YES];
		[window makeKeyAndOrderFront:nil];
		[text focus];
	}
	else {
		[NSApp hide:nil];
	}
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	return NSTerminateNow;
}

- (void)applicationWillTerminate:(NSNotification *)note
{
	// unregister URL handler
	NSAppleEventManager* em = [NSAppleEventManager sharedAppleEventManager];
	[em removeEventHandlerForEventClass:KInternetEventClass andEventID:KAEGetURL];
	
	[menu terminate];
	[NSApp unregisterHotKey];
	[self saveWindowState];
}

#pragma mark -
#pragma mark NSWorkspace Notifications

- (void)computerWillSleep:(NSNotification*)note
{
}

- (void)computerDidWakeUp:(NSNotification*)note
{
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

#pragma mark -
#pragma mark Utilities

- (void)sendText:(NSString*)command
{
	NSString* s = [text stringValue];
	if (s.length) {
		if ([world sendText:s command:command]) {
			[inputHistory add:s];
			[text setStringValue:@""];
		}
	}
	[text focus];
	
	// completion
}

- (void)textEntered:(id)sender
{
	[self sendText:PRIVMSG];
}

- (void)set3columnLayout:(BOOL)value
{
	if (value == [infoSplitter isHidden]) return;
	
	if (value) {
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
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	NSDictionary* dic = [ud dictionaryForKey:@"main_window"];
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
	
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setObject:dic forKey:@"main_window"];
	[ud synchronize];
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
	if ([window firstResponder] == [text currentEditor]) {
		id sel = world.selected;
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
}

- (void)scrollToTop:(NSEvent*)e
{
	[self scroll:SCROLL_TOP];
}

- (void)scrollToBottom:(NSEvent*)e
{
	[self scroll:SCROLL_BOTTOM];
}

- (void)scrollPageUp:(NSEvent*)e
{
	[self scroll:SCROLL_PAGE_UP];
}

- (void)scrollPageDown:(NSEvent*)e
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
					if (client.loggedIn) {
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

- (void)tag:(NSEvent*)e
{
}

- (void)shiftTab:(NSEvent*)e
{
}

- (void)sendPrivmsg:(NSEvent*)e
{
}

- (void)sendNotice:(NSEvent*)e
{
}

- (void)showPasteDialog:(NSEvent*)e
{
}

- (void)inputHistoryUp:(NSEvent*)e
{
	NSString* s = [inputHistory up:[text stringValue]];
	if (s) {
		[text setStringValue:s];
		[world selectText];
	}
}

- (void)inputHistoryDown:(NSEvent*)e
{
	NSString* s = [inputHistory down:[text stringValue]];
	if (s) {
		[text setStringValue:s];
		[world selectText];
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
	
	[self handler:@selector(scrollToTop:) code:KEY_HOME mods:0];
	[self handler:@selector(scrollToBottom:) code:KEY_END mods:0];
	[self handler:@selector(scrollPageUp:) code:KEY_PAGE_UP mods:0];
	[self handler:@selector(scrollPageDown:) code:KEY_PAGE_DOWN mods:0];
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
	
	[self inputHandler:@selector(inputHistoryUp:) code:KEY_UP mods:0];
	[self inputHandler:@selector(inputHistoryUp:) code:KEY_UP mods:NSAlternateKeyMask];
	[self inputHandler:@selector(inputHistoryDown:) code:KEY_DOWN mods:0];
	[self inputHandler:@selector(inputHistoryDown:) code:KEY_DOWN mods:NSAlternateKeyMask];
}

#pragma mark -
#pragma mark Migration

- (void)prelude
{
	[NewPreferences migrate];
}

@end
