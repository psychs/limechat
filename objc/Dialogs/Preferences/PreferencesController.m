// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "PreferencesController.h"
#import "Preferences.h"
#import "LimeChatApplication.h"
#import "SoundWrapper.h"


#define LOG_MAX_LINES_MIN	100
#define PORT_MIN			1024
#define PORT_MAX			65535


@interface PreferencesController (Private)
- (void)loadHotKey;
- (void)updateTranscriptFolder;
@end


@implementation PreferencesController

@synthesize delegate;

- (id)init
{
	if (self = [super init]) {
		[NSBundle loadNibNamed:@"Preferences" owner:self];
	}
	return self;
}

- (void)dealloc
{
	[sounds release];
	[transcriptFolderOpenPanel release];
	[super dealloc];
}

#pragma mark -
#pragma mark Utilities

- (void)show
{
	[self loadHotKey];
	[self updateTranscriptFolder];
	
	[self.window makeKeyAndOrderFront:nil];
}

#pragma mark -
#pragma mark KVC Properties

- (void)setFontDisplayName:(NSString*)value
{
}

- (NSString*)fontDisplayName
{
	return @"";
}

- (void)setFontPointSize:(CGFloat)value
{
}

- (CGFloat)fontPointSize
{
	return 12;
}

- (int)dccFirstPort
{
	return [NewPreferences dccFirstPort];
}

- (void)setDccFirstPort:(int)value
{
	[NewPreferences setDccFirstPort:value];
}

- (int)dccLastPort
{
	return [NewPreferences dccLastPort];
}

- (void)setDccLastPort:(int)value
{
	[NewPreferences setDccLastPort:value];
}

- (int)maxLogLines
{
	return [NewPreferences maxLogLines];
}

- (void)setMaxLogLines:(int)value
{
	[NewPreferences setMaxLogLines:value];
}

- (BOOL)validateValue:(id *)value forKey:(NSString *)key error:(NSError **)error
{
	if ([key isEqualToString:@"maxLogLines"]) {
		int n = [*value intValue];
		if (n < LOG_MAX_LINES_MIN) {
			*value = [NSNumber numberWithInt:LOG_MAX_LINES_MIN];
		}
	}
	else if ([key isEqualToString:@"dccFirstPort"]) {
		int n = [*value intValue];
		if (n < PORT_MIN) {
			*value = [NSNumber numberWithInt:PORT_MIN];
		}
		else if (PORT_MAX < n) {
			*value = [NSNumber numberWithInt:PORT_MAX];
		}
	}
	else if ([key isEqualToString:@"dccLastPort"]) {
		int n = [*value intValue];
		if (n < PORT_MIN) {
			*value = [NSNumber numberWithInt:PORT_MIN];
		}
		else if (PORT_MAX < n) {
			*value = [NSNumber numberWithInt:PORT_MAX];
		}
	}
	return YES;
}

#pragma mark -
#pragma mark Hot Key

- (void)loadHotKey
{
	hotKey.keyCode = [NewPreferences hotKeyKeyCode];
	hotKey.modifierFlags = [NewPreferences hotKeyModifierFlags];
}

- (void)keyRecorderDidChangeKey:(KeyRecorder*)sender
{
	int code = hotKey.keyCode;
	NSUInteger mods = hotKey.modifierFlags;
	
	[NewPreferences setHotKeyKeyCode:code];
	[NewPreferences setHotKeyModifierFlags:mods];
	
	if (hotKey.keyCode) {
		[(LimeChatApplication*)NSApp registerHotKey:code modifierFlags:mods];
	}
	else {
		[(LimeChatApplication*)NSApp unregisterHotKey];
	}
}

#pragma mark -
#pragma mark Sounds

- (NSArray*)availableSounds
{
	static NSArray* ary;
	if (!ary) {
		ary = [[NSArray arrayWithObjects:@"-", @"Beep", @"Basso", @"Blow", @"Bottle", @"Frog", @"Funk", @"Glass", @"Hero", @"Morse", @"Ping", @"Purr", @"Sosumi", @"Submarine", @"Tink", nil] retain];
	}
	return ary;
}

- (NSMutableArray*)sounds
{
	if (!sounds) {
		NSMutableArray* ary = [NSMutableArray new];
		SoundWrapper* e;
		NSString* s;
		
		s = [NewPreferences soundLogin];
		e = [[[SoundWrapper alloc] initWithDisplayName:@"Login" sound:s saveSelector:@selector(setSoundLogin:)] autorelease];
		[ary addObject:e];
		
		s = [NewPreferences soundDisconnect];
		e = [[[SoundWrapper alloc] initWithDisplayName:@"Disconnected" sound:s saveSelector:@selector(setSoundDisconnect:)] autorelease];
		[ary addObject:e];
		
		s = [NewPreferences soundHighlight];
		e = [[[SoundWrapper alloc] initWithDisplayName:@"Highlight" sound:s saveSelector:@selector(setSoundHighlight:)] autorelease];
		[ary addObject:e];
		
		s = [NewPreferences soundNewtalk];
		e = [[[SoundWrapper alloc] initWithDisplayName:@"New talk" sound:s saveSelector:@selector(setSoundNewtalk:)] autorelease];
		[ary addObject:e];
		
		s = [NewPreferences soundKicked];
		e = [[[SoundWrapper alloc] initWithDisplayName:@"Kicked" sound:s saveSelector:@selector(setSoundKicked:)] autorelease];
		[ary addObject:e];
		
		s = [NewPreferences soundInvited];
		e = [[[SoundWrapper alloc] initWithDisplayName:@"Invited" sound:s saveSelector:@selector(setSoundInvited:)] autorelease];
		[ary addObject:e];
		
		s = [NewPreferences soundChanneltext];
		e = [[[SoundWrapper alloc] initWithDisplayName:@"Channel text" sound:s saveSelector:@selector(setSoundChanneltext:)] autorelease];
		[ary addObject:e];
		
		s = [NewPreferences soundTalktext];
		e = [[[SoundWrapper alloc] initWithDisplayName:@"Talk text" sound:s saveSelector:@selector(setSoundTalktext:)] autorelease];
		[ary addObject:e];
		
		s = [NewPreferences soundFileReceiveRequest];
		e = [[[SoundWrapper alloc] initWithDisplayName:@"DCC file receive request" sound:s saveSelector:@selector(setSoundFileReceiveRequest:)] autorelease];
		[ary addObject:e];
		
		s = [NewPreferences soundFileReceiveSuccess];
		e = [[[SoundWrapper alloc] initWithDisplayName:@"DCC file receive success" sound:s saveSelector:@selector(setSoundFileReceiveSuccess:)] autorelease];
		[ary addObject:e];
		
		s = [NewPreferences soundFileReceiveFailure];
		e = [[[SoundWrapper alloc] initWithDisplayName:@"DCC file receive failure" sound:s saveSelector:@selector(setSoundFileReceiveFailure:)] autorelease];
		[ary addObject:e];
		
		s = [NewPreferences soundFileSendSuccess];
		e = [[[SoundWrapper alloc] initWithDisplayName:@"DCC file send success" sound:s saveSelector:@selector(setSoundFileSendSuccess:)] autorelease];
		[ary addObject:e];
		
		s = [NewPreferences soundFileSendFailure];
		e = [[[SoundWrapper alloc] initWithDisplayName:@"DCC file send failure" sound:s saveSelector:@selector(setSoundFileSendFailure:)] autorelease];
		[ary addObject:e];
		
		sounds = ary;
	}
	return sounds;
}

#pragma mark -
#pragma mark Transcript Folder Popup

- (void)updateTranscriptFolder
{
	NSString* path = [NewPreferences transcriptFolder];
	path = [path stringByExpandingTildeInPath];
	NSString* dirName = [path lastPathComponent];
	
	NSImage* icon = [[NSWorkspace sharedWorkspace] iconForFile:path];
	[icon setSize:NSMakeSize(16, 16)];
	
	NSMenuItem* item = [transcriptFolderButton itemAtIndex:0];
	[item setTitle:dirName];
	[item setImage:icon];
}

- (void)transcriptFolderPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
	[transcriptFolderButton selectItem:[transcriptFolderButton itemAtIndex:0]];
	
	if (returnCode == NSOKButton) {
		NSString* path = [[panel filenames] objectAtIndex:0];
		
		// create directory
		NSFileManager* fm = [NSFileManager defaultManager];
		BOOL isDir;
		if (![fm fileExistsAtPath:path isDirectory:&isDir]) {
			[fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:NULL];
		}
		
		[NewPreferences setTranscriptFolder:[path stringByAbbreviatingWithTildeInPath]];
		[self updateTranscriptFolder];
	}
		
	[transcriptFolderOpenPanel autorelease];
	transcriptFolderOpenPanel = nil;
}

- (void)onTranscriptFolderChanged:(id)sender
{
	if ([[transcriptFolderButton selectedItem] tag] != 2) return;
	
	NSString* path = [NewPreferences transcriptFolder];
	path = [path stringByExpandingTildeInPath];
	NSString* parentPath = [path stringByDeletingLastPathComponent];
	
	NSOpenPanel* d = [NSOpenPanel openPanel];
	[d setCanChooseFiles:NO];
	[d setCanChooseDirectories:YES];
	[d setResolvesAliases:YES];
	[d setAllowsMultipleSelection:NO];
	[d setCanCreateDirectories:YES];
	[d beginForDirectory:parentPath file:nil types:nil modelessDelegate:self didEndSelector:@selector(transcriptFolderPanelDidEnd:returnCode:contextInfo:) contextInfo:nil];
	
	[transcriptFolderOpenPanel release];
	transcriptFolderOpenPanel = [d retain];
}

#pragma mark -
#pragma mark Actions

- (void)editTable:(NSTableView*)table
{
	int row = [table numberOfRows] - 1;
	[table scrollRowToVisible:row];
	[table editColumn:0 row:row withEvent:nil select:YES];
}

- (void)onAddKeyword:(id)sender
{
	[keywordsArrayController add:nil];
	[self performSelector:@selector(editTable:) withObject:keywordsTable afterDelay:0];
}

- (void)onAddExcludeWord:(id)sender
{
	[excludeWordsArrayController add:nil];
	[self performSelector:@selector(editTable:) withObject:excludeWordsTable afterDelay:0];
}

- (void)onAddIgnoreWord:(id)sender
{
	[ignoreWordsArrayController add:nil];
	[self performSelector:@selector(editTable:) withObject:ignoreWordsTable afterDelay:0];
}

- (void)onLayoutChanged:(id)sender
{
}

- (void)onChangedTheme:(id)sender
{
}

- (void)onOpenThemePath:(id)sender
{
}

- (void)onSelectFont:(id)sender
{
}

- (void)onChangedTransparency:(id)sender
{
}

@end
