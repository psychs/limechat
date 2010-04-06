#import "AppController.h"
#import "Preferences.h"
#import "IRCTreeItem.h"
#import "NSDictionaryHelper.h"
#import "IRC.h"
#import "IRCWorld.h"


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
	
	//@@@ menu controller
	
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

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	return NSTerminateNow;
}

- (void)applicationDidBecomeActive:(NSNotification *)note
{
	id sel = world.selectedItem;
	if (sel) {
		[sel resetState];
		[world updateIcon];
	}
}

- (void)applicationDidResignActive:(NSNotification *)note
{
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

- (void)applicationWillTerminate:(NSNotification *)note
{
	// unregister URL handler
	NSAppleEventManager* em = [NSAppleEventManager sharedAppleEventManager];
	[em removeEventHandlerForEventClass:KInternetEventClass andEventID:KAEGetURL];
	
	[NSApp unregisterHotKey];
	[self saveWindowState];
}

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

- (id)windowWillReturnFieldEditor:(NSWindow *)sender toObject:(id)client
{
	if (client == text) {
		return fieldEditor;
	}
	else {
		return nil;
	}
}

- (void)handleURLEvent:(NSAppleEventDescriptor*)event withReplyEvent:(NSAppleEventDescriptor*)replyEvent
{
	//NSString* url = [[event descriptorAtIndex:1] stringValue];
	//LOG(@"%@", url);
}

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

- (void)registerKeyHandlers
{
}

- (void)prelude
{
}

@end
