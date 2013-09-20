// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "PreferencesController.h"
#import "Preferences.h"
#import "ViewTheme.h"
#import "LimeChatApplication.h"
#import "SoundWrapper.h"


#define LINES_MIN			100
#define PORT_MIN			1024
#define PORT_MAX			65535
#define PONG_INTERVAL_MIN	20


@implementation PreferencesController

@synthesize delegate;

- (id)init
{
    self = [super init];
    if (self) {
        [NSBundle loadNibNamed:@"Preferences" owner:self];
    }
    return self;
}

- (void)dealloc
{
    [sounds release];
    [transcriptFolderOpenPanel release];
    [logFont release];
    [inputFont release];
    [super dealloc];
}

#pragma mark -
#pragma mark Utilities

- (void)awakeFromNib
{
    SInt32 version = 0;
    Gestalt(gestaltSystemVersion, &version);
    if (version >= 0x1080) {
        NSArray* columns = [soundsTable tableColumns];
        if (columns.count > 3) {
            [soundsTable removeTableColumn:[columns objectAtIndex:2]];
        }
    }
}

- (void)show
{
    [self loadHotKey];
    [self updateTranscriptFolder];
    [self updateTheme];

    [logFont release];
    logFont = [[NSFont fontWithName:[Preferences themeLogFontName] size:[Preferences themeLogFontSize]] retain];

    [inputFont release];
    inputFont = [[NSFont fontWithName:[Preferences themeInputFontName] size:[Preferences themeInputFontSize]] retain];

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

- (void)setInputFontDisplayName:(NSString*)value
{
    [Preferences setThemeInputFontName:value];
}

- (NSString*)inputFontDisplayName
{
    return [Preferences themeInputFontName];
}

- (void)setInputFontPointSize:(CGFloat)value
{
    [Preferences setThemeInputFontSize:value];
}

- (CGFloat)inputFontPointSize
{
    return [Preferences themeInputFontSize];
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

- (int)pongInterval
{
    return [Preferences pongInterval];
}

- (void)setPongInterval:(int)value
{
    [Preferences setPongInterval:value];
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
    else if ([key isEqualToString:@"pongInterval"]) {
        int n = [*value intValue];
        if (n < PONG_INTERVAL_MIN) {
            *value = [NSNumber numberWithInt:PONG_INTERVAL_MIN];
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
	NSMutableSet * soundFiles = [NSMutableSet set];
	
	NSFileManager * fm = [NSFileManager defaultManager];
	
    NSString * SytemSoundFiles = @"/System/Library/Sounds";
    
    NSString * RootLibrarySoundFiles = @"/Library/Sounds";
    
    NSString * UserSoundFiles = @"~/Library/Sounds";
    
    NSError* error = nil;
    
    UserSoundFiles = [UserSoundFiles stringByExpandingTildeInPath];
    
	for (NSString * file in [fm contentsOfDirectoryAtPath:RootLibrarySoundFiles error: &error])
	{
		if (![file isEqualToString:@".DS_Store"])
			[soundFiles addObject:[file stringByDeletingPathExtension]];
	}
    
	for (NSString * file in [fm contentsOfDirectoryAtPath:SytemSoundFiles error: &error])
	{
		if (![file isEqualToString:@".DS_Store"])
			[soundFiles addObject:[file stringByDeletingPathExtension]];
	}
    
	for (NSString * file in [fm contentsOfDirectoryAtPath:UserSoundFiles error: &error])
	{
		if (![file isEqualToString:@".DS_Store"])
			[soundFiles addObject:[file stringByDeletingPathExtension]];
	}
	
    if(error != nil) {
        NSLog(@"Error in reading files: %@", [error localizedDescription]);
    }
    
	return [[soundFiles allObjects] sortedArrayUsingSelector:@selector(compare:)];
}

- (NSMutableArray*)sounds
{
    if (!sounds) {
        NSMutableArray* ary = [NSMutableArray new];
        SoundWrapper* e;

        e = [SoundWrapper soundWrapperWithEventType:USER_NOTIFICATION_LOGIN];
        [ary addObject:e];

        e = [SoundWrapper soundWrapperWithEventType:USER_NOTIFICATION_DISCONNECT];
        [ary addObject:e];

        e = [SoundWrapper soundWrapperWithEventType:USER_NOTIFICATION_HIGHLIGHT];
        [ary addObject:e];

        e = [SoundWrapper soundWrapperWithEventType:USER_NOTIFICATION_NEW_TALK];
        [ary addObject:e];

        e = [SoundWrapper soundWrapperWithEventType:USER_NOTIFICATION_KICKED];
        [ary addObject:e];

        e = [SoundWrapper soundWrapperWithEventType:USER_NOTIFICATION_INVITED];
        [ary addObject:e];

        e = [SoundWrapper soundWrapperWithEventType:USER_NOTIFICATION_CHANNEL_MSG];
        [ary addObject:e];

        e = [SoundWrapper soundWrapperWithEventType:USER_NOTIFICATION_CHANNEL_NOTICE];
        [ary addObject:e];

        e = [SoundWrapper soundWrapperWithEventType:USER_NOTIFICATION_TALK_MSG];
        [ary addObject:e];

        e = [SoundWrapper soundWrapperWithEventType:USER_NOTIFICATION_TALK_NOTICE];
        [ary addObject:e];

        e = [SoundWrapper soundWrapperWithEventType:USER_NOTIFICATION_FILE_RECEIVE_REQUEST];
        [ary addObject:e];

        e = [SoundWrapper soundWrapperWithEventType:USER_NOTIFICATION_FILE_RECEIVE_SUCCESS];
        [ary addObject:e];

        e = [SoundWrapper soundWrapperWithEventType:USER_NOTIFICATION_FILE_RECEIVE_ERROR];
        [ary addObject:e];

        e = [SoundWrapper soundWrapperWithEventType:USER_NOTIFICATION_FILE_SEND_SUCCESS];
        [ary addObject:e];

        e = [SoundWrapper soundWrapperWithEventType:USER_NOTIFICATION_FILE_SEND_ERROR];
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
        NSString* path = [[[panel URLs] objectAtIndex:0] path];

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
    d.directoryURL = [NSURL fileURLWithPath:parentPath isDirectory:YES];

    __block PreferencesController* blockSelf = self;
    [d beginWithCompletionHandler:^(NSInteger result) {
        [blockSelf transcriptFolderPanelDidEnd:d returnCode:result contextInfo:NULL];
    }];

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
    changingLogFont = YES;

    NSFontManager* fm = [NSFontManager sharedFontManager];
    [fm setSelectedFont:logFont isMultiple:NO];
    [fm orderFrontFontPanel:self];
}

- (void)onInputSelectFont:(id)sender
{
    changingLogFont = NO;

    NSFontManager* fm = [NSFontManager sharedFontManager];
    [fm setSelectedFont:inputFont isMultiple:NO];
    [fm orderFrontFontPanel:self];
}

- (void)changeFont:(id)sender
{
    if (changingLogFont) {
        [logFont autorelease];
        logFont = [[sender convertFont:logFont] retain];
        [self setValue:logFont.fontName forKey:@"fontDisplayName"];
        [self setValue:[NSNumber numberWithDouble:logFont.pointSize] forKey:@"fontPointSize"];
    }
    else {
        [inputFont autorelease];
        inputFont = [[sender convertFont:inputFont] retain];
        [self setValue:inputFont.fontName forKey:@"inputFontDisplayName"];
        [self setValue:[NSNumber numberWithDouble:inputFont.pointSize] forKey:@"inputFontPointSize"];
    }

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
    [self performSelector:@selector(editTable:) withObject:keywordsTable afterDelay:0.01];
}

- (void)onAddExcludeWord:(id)sender
{
    [excludeWordsArrayController add:nil];
    [self performSelector:@selector(editTable:) withObject:excludeWordsTable afterDelay:0.01];
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
    [self.window endEditingFor:nil];

    [Preferences cleanUpWords];
    [Preferences sync];

    if ([delegate respondsToSelector:@selector(preferencesDialogWillClose:)]) {
        [delegate preferencesDialogWillClose:self];
    }
}

@end
