// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "PreferencesController.h"
#import "Preferences.h"
#import "ViewTheme.h"
#import "LimeChatApplication.h"
#import "SoundWrapper.h"


#define LINES_MIN			100
#define PORT_MIN			1024
#define PORT_MAX			65535


@interface PreferencesController (Private)
- (void)loadHotKey;
- (void)updateTranscriptFolder;
- (void)updateTheme;
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
	[logFont release];
	[super dealloc];
}

#pragma mark -
#pragma mark Utilities

- (void)show
{
	[self loadHotKey];
	[self updateTranscriptFolder];
	[self updateTheme];
	
	[logFont release];
	logFont = [[NSFont fontWithName:[Preferences themeLogFontName] size:[Preferences themeLogFontSize]] retain];
	
	if (![self.window isVisible]) {
		[self.window center];
	}
	
	[self.window makeKeyAndOrderFront:nil];
}

#pragma mark -
#pragma mark KVC Properties

- (void)setFontDisplayName:(NSString*)value
{
	[Preferences setThemeLogFontName:value];
}

- (NSString*)fontDisplayName
{
	return [Preferences themeLogFontName];
}

- (void)setFontPointSize:(CGFloat)value
{
	[Preferences setThemeLogFontSize:value];
}

- (CGFloat)fontPointSize
{
	return [Preferences themeLogFontSize];
}

- (int)dccFirstPort
{
	return [Preferences dccFirstPort];
}

- (void)setDccFirstPort:(int)value
{
	[Preferences setDccFirstPort:value];
}

- (int)dccLastPort
{
	return [Preferences dccLastPort];
}

- (void)setDccLastPort:(int)value
{
	[Preferences setDccLastPort:value];
}

- (int)maxLogLines
{
	return [Preferences maxLogLines];
}

- (void)setMaxLogLines:(int)value
{
	[Preferences setMaxLogLines:value];
}

- (BOOL)validateValue:(id *)value forKey:(NSString *)key error:(NSError **)error
{
	if ([key isEqualToString:@"maxLogLines"]) {
		int n = [*value intValue];
		if (n < LINES_MIN) {
			*value = [NSNumber numberWithInt:LINES_MIN];
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
	hotKey.keyCode = [Preferences hotKeyKeyCode];
	hotKey.modifierFlags = [Preferences hotKeyModifierFlags];
}

- (void)keyRecorderDidChangeKey:(KeyRecorder*)sender
{
	int code = hotKey.keyCode;
	NSUInteger mods = hotKey.modifierFlags;
	
	[Preferences setHotKeyKeyCode:code];
	[Preferences setHotKeyModifierFlags:mods];
	
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
		ary = [[NSArray arrayWithObjects:@"-", @"Beep", @"Basso", @"Blow", @"Bottle", @"Frog", @"Funk", @"Glass", @"Hero", @"Morse", @"Ping", @"Pop", @"Purr", @"Sosumi", @"Submarine", @"Tink", nil] retain];
	}
	return ary;
}

- (NSMutableArray*)sounds
{
	if (!sounds) {
		NSMutableArray* ary = [NSMutableArray new];
		SoundWrapper* e;
		
		e = [SoundWrapper soundWrapperWithEventType:GROWL_LOGIN];
		[ary addObject:e];
		
		e = [SoundWrapper soundWrapperWithEventType:GROWL_DISCONNECT];
		[ary addObject:e];
		
		e = [SoundWrapper soundWrapperWithEventType:GROWL_HIGHLIGHT];
		[ary addObject:e];
		
		e = [SoundWrapper soundWrapperWithEventType:GROWL_NEW_TALK];
		[ary addObject:e];
		
		e = [SoundWrapper soundWrapperWithEventType:GROWL_KICKED];
		[ary addObject:e];
		
		e = [SoundWrapper soundWrapperWithEventType:GROWL_INVITED];
		[ary addObject:e];
		
		e = [SoundWrapper soundWrapperWithEventType:GROWL_CHANNEL_MSG];
		[ary addObject:e];
		
		e = [SoundWrapper soundWrapperWithEventType:GROWL_CHANNEL_NOTICE];
		[ary addObject:e];
		
		e = [SoundWrapper soundWrapperWithEventType:GROWL_TALK_MSG];
		[ary addObject:e];
		
		e = [SoundWrapper soundWrapperWithEventType:GROWL_TALK_NOTICE];
		[ary addObject:e];
		
		e = [SoundWrapper soundWrapperWithEventType:GROWL_FILE_RECEIVE_REQUEST];
		[ary addObject:e];
		
		e = [SoundWrapper soundWrapperWithEventType:GROWL_FILE_RECEIVE_SUCCESS];
		[ary addObject:e];
		
		e = [SoundWrapper soundWrapperWithEventType:GROWL_FILE_RECEIVE_ERROR];
		[ary addObject:e];
		
		e = [SoundWrapper soundWrapperWithEventType:GROWL_FILE_SEND_SUCCESS];
		[ary addObject:e];
		
		e = [SoundWrapper soundWrapperWithEventType:GROWL_FILE_SEND_ERROR];
		[ary addObject:e];
		
		sounds = ary;
	}
	return sounds;
}

#pragma mark -
#pragma mark Transcript Folder Popup

- (void)updateTranscriptFolder
{
	NSString* path = [Preferences transcriptFolder];
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
		
		[Preferences setTranscriptFolder:[path stringByAbbreviatingWithTildeInPath]];
		[self updateTranscriptFolder];
	}
		
	[transcriptFolderOpenPanel autorelease];
	transcriptFolderOpenPanel = nil;
}

- (void)onTranscriptFolderChanged:(id)sender
{
	if ([transcriptFolderButton selectedTag] != 2) return;
	
	NSString* path = [Preferences transcriptFolder];
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
#pragma mark Theme

- (void)updateTheme
{
	//
	// update menu
	//
	
	[themeButton removeAllItems];
	[themeButton addItemWithTitle:@"Default"];
	[[themeButton itemAtIndex:0] setTag:0];
	
	NSFileManager* fm = [NSFileManager defaultManager];
	NSArray* ary = [NSArray arrayWithObjects:[ViewTheme resourceBasePath], [ViewTheme userBasePath], nil];
	int tag = 0;
	
	for (NSString* path in ary) {
		NSMutableSet* set = [NSMutableSet set];
		NSArray* files = [fm contentsOfDirectoryAtPath:path error:NULL];
		for (NSString* file in files) {
			if ([file hasSuffix:@".css"] || [file hasSuffix:@".yaml"]) {
				NSString* baseName = [file stringByDeletingPathExtension];
				if (tag == 0 && [baseName isEqualToString:@"Sample"]) {
					continue;
				}
				[set addObject:baseName];
			}
		}
		
		files = [[set allObjects] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
		if (files.count) {
			[themeButton.menu addItem:[NSMenuItem separatorItem]];
			
			int i = 0;
			for (NSString* f in files) {
				NSMenuItem* item = [[[NSMenuItem alloc] initWithTitle:f action:nil keyEquivalent:@""] autorelease];
				[item setTag:tag];
				[themeButton.menu addItem:item];
				++i;
			}
		}
		
		++tag;
	}
	
	//
	// select current one
	//
	
	NSArray* kindAndName = [ViewTheme extractFileName:[Preferences themeName]];
	if (!kindAndName) {
		[themeButton selectItemAtIndex:0];
		return;
	}
	
	NSString* kind = [kindAndName objectAtIndex:0];
	NSString* name = [kindAndName objectAtIndex:1];
	
	int targetTag = 0;
	if (![kind isEqualToString:@"resource"]) {
		targetTag = 1;
	}
	
	int count = [themeButton numberOfItems];
	for (int i=0; i<count; i++) {
		NSMenuItem* item = [themeButton itemAtIndex:i];
		if ([item tag] == targetTag && [[item title] isEqualToString:name]) {
			[themeButton selectItemAtIndex:i];
			break;
		}
	}
}

- (void)onChangedTheme:(id)sender
{
	NSMenuItem* item = [themeButton selectedItem];
	NSString* name = [item title];
	if (item.tag == 0) {
		[Preferences setThemeName:[ViewTheme buildResourceFileName:name]];
	}
	else {
		[Preferences setThemeName:[ViewTheme buildUserFileName:name]];
	}
	[self onLayoutChanged:nil];
}

- (void)onOpenThemePath:(id)sender
{
	NSString* path = [ViewTheme userBasePath];
	[[NSWorkspace sharedWorkspace] openFile:path];
}

- (void)onSelectFont:(id)sender
{
	NSFontManager* fm = [NSFontManager sharedFontManager];
	[fm setSelectedFont:logFont isMultiple:NO];
	[fm orderFrontFontPanel:self];
}

- (void)changeFont:(id)sender
{
	[logFont autorelease];
	logFont = [[sender convertFont:logFont] retain];
	
	[self setValue:logFont.fontName forKey:@"fontDisplayName"];
	[self setValue:[NSNumber numberWithDouble:logFont.pointSize] forKey:@"fontPointSize"];
	
	[self onLayoutChanged:nil];
}

- (void)onOverrideFontChanged:(id)sender
{
	[self onLayoutChanged:nil];
}

- (void)onChangedTransparency:(id)sender
{
	[self onLayoutChanged:nil];
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
	NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
	[nc postNotificationName:ThemeDidChangeNotification object:nil userInfo:nil];
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification *)note
{
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	if ([delegate respondsToSelector:@selector(preferencesDialogWillClose:)]) {
		[delegate preferencesDialogWillClose:self];
	}
}

@end
