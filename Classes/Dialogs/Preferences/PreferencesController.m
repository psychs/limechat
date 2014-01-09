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
{
    NSMutableArray* _sounds;
    NSOpenPanel* _transcriptFolderOpenPanel;
    NSFont* _logFont;
    NSFont* _inputFont;
    BOOL _changingLogFont;
}

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
    _keywordsTable.delegate = nil;
    _keywordsTable.dataSource = nil;
    _excludeWordsTable.delegate = nil;
    _excludeWordsTable.dataSource = nil;
    _soundsTable.delegate = nil;
    _soundsTable.dataSource = nil;
}

#pragma mark - Utilities

- (void)show
{
    [self loadHotKey];
    [self updateTranscriptFolder];
    [self updateTheme];

    _logFont = [NSFont fontWithName:[Preferences themeLogFontName] size:[Preferences themeLogFontSize]];
    _inputFont = [NSFont fontWithName:[Preferences themeInputFontName] size:[Preferences themeInputFontSize]];

    if (![self.window isVisible]) {
        [self.window center];
    }

    [self.window makeKeyAndOrderFront:nil];
}

#pragma mark - KVC Properties

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
            *value = @(LINES_MIN);
        }
    }
    else if ([key isEqualToString:@"dccFirstPort"]) {
        int n = [*value intValue];
        if (n < PORT_MIN) {
            *value = @(PORT_MIN);
        }
        else if (PORT_MAX < n) {
            *value = @(PORT_MAX);
        }
    }
    else if ([key isEqualToString:@"dccLastPort"]) {
        int n = [*value intValue];
        if (n < PORT_MIN) {
            *value = @(PORT_MIN);
        }
        else if (PORT_MAX < n) {
            *value = @(PORT_MAX);
        }
    }
    else if ([key isEqualToString:@"pongInterval"]) {
        int n = [*value intValue];
        if (n < PONG_INTERVAL_MIN) {
            *value = @(PONG_INTERVAL_MIN);
        }
    }
    return YES;
}

#pragma mark - Hot Key

- (void)loadHotKey
{
    _hotKey.keyCode = [Preferences hotKeyKeyCode];
    _hotKey.modifierFlags = [Preferences hotKeyModifierFlags];
}

- (void)keyRecorderDidChangeKey:(KeyRecorder*)sender
{
    int code = _hotKey.keyCode;
    NSUInteger mods = _hotKey.modifierFlags;

    [Preferences setHotKeyKeyCode:code];
    [Preferences setHotKeyModifierFlags:mods];

    if (_hotKey.keyCode) {
        [(LimeChatApplication*)NSApp registerHotKey:code modifierFlags:mods];
    }
    else {
        [(LimeChatApplication*)NSApp unregisterHotKey];
    }
}

#pragma mark - Sounds

- (NSArray*)availableSounds
{
    static NSArray* ary;
    if (!ary) {
        ary = [NSArray arrayWithObjects:@"-", @"Beep", @"Basso", @"Blow", @"Bottle", @"Frog", @"Funk", @"Glass", @"Hero", @"Morse", @"Ping", @"Pop", @"Purr", @"Sosumi", @"Submarine", @"Tink", nil];
    }
    return ary;
}

- (NSMutableArray*)sounds
{
    if (!_sounds) {
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

        _sounds = ary;
    }
    return _sounds;
}

#pragma mark - Transcript Folder Popup

- (void)updateTranscriptFolder
{
    NSString* path = [Preferences transcriptFolder];
    path = [path stringByExpandingTildeInPath];
    NSString* dirName = [path lastPathComponent];

    NSImage* icon = [[NSWorkspace sharedWorkspace] iconForFile:path];
    [icon setSize:NSMakeSize(16, 16)];

    NSMenuItem* item = [_transcriptFolderButton itemAtIndex:0];
    [item setTitle:dirName];
    [item setImage:icon];
}

- (void)transcriptFolderPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    [_transcriptFolderButton selectItem:[_transcriptFolderButton itemAtIndex:0]];

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

    _transcriptFolderOpenPanel = nil;
}

- (void)onTranscriptFolderChanged:(id)sender
{
    if ([_transcriptFolderButton selectedTag] != 2) return;

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

    _transcriptFolderOpenPanel = d;
}

#pragma mark - Theme

- (void)updateTheme
{
    //
    // update menu
    //

    [_themeButton removeAllItems];
    [_themeButton addItemWithTitle:@"Default"];
    [[_themeButton itemAtIndex:0] setTag:0];

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
            [_themeButton.menu addItem:[NSMenuItem separatorItem]];

            int i = 0;
            for (NSString* f in files) {
                NSMenuItem* item = [[NSMenuItem alloc] initWithTitle:f action:nil keyEquivalent:@""];
                [item setTag:tag];
                [_themeButton.menu addItem:item];
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
        [_themeButton selectItemAtIndex:0];
        return;
    }

    NSString* kind = [kindAndName objectAtIndex:0];
    NSString* name = [kindAndName objectAtIndex:1];

    int targetTag = 0;
    if (![kind isEqualToString:@"resource"]) {
        targetTag = 1;
    }

    int count = [_themeButton numberOfItems];
    for (int i=0; i<count; i++) {
        NSMenuItem* item = [_themeButton itemAtIndex:i];
        if ([item tag] == targetTag && [[item title] isEqualToString:name]) {
            [_themeButton selectItemAtIndex:i];
            break;
        }
    }
}

- (void)onChangedTheme:(id)sender
{
    NSMenuItem* item = [_themeButton selectedItem];
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
    _changingLogFont = YES;

    NSFontManager* fm = [NSFontManager sharedFontManager];
    [fm setSelectedFont:_logFont isMultiple:NO];
    [fm orderFrontFontPanel:self];
}

- (void)onInputSelectFont:(id)sender
{
    _changingLogFont = NO;

    NSFontManager* fm = [NSFontManager sharedFontManager];
    [fm setSelectedFont:_inputFont isMultiple:NO];
    [fm orderFrontFontPanel:self];
}

- (void)changeFont:(id)sender
{
    if (_changingLogFont) {
        _logFont = [sender convertFont:_logFont];
        [self setValue:_logFont.fontName forKey:@"fontDisplayName"];
        [self setValue:@(_logFont.pointSize) forKey:@"fontPointSize"];
    }
    else {
        _inputFont = [sender convertFont:_inputFont];
        [self setValue:_inputFont.fontName forKey:@"inputFontDisplayName"];
        [self setValue:@(_inputFont.pointSize) forKey:@"inputFontPointSize"];
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

#pragma mark - Actions

- (void)editTable:(NSTableView*)table
{
    int row = [table numberOfRows] - 1;
    [table scrollRowToVisible:row];
    [table editColumn:0 row:row withEvent:nil select:YES];
}

- (void)onAddKeyword:(id)sender
{
    [_keywordsArrayController add:nil];
    [self performSelector:@selector(editTable:) withObject:_keywordsTable afterDelay:0.01];
}

- (void)onAddExcludeWord:(id)sender
{
    [_excludeWordsArrayController add:nil];
    [self performSelector:@selector(editTable:) withObject:_excludeWordsTable afterDelay:0.01];
}

- (void)onLayoutChanged:(id)sender
{
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:ThemeDidChangeNotification object:nil userInfo:nil];
}

#pragma mark - NSWindow Delegate

- (void)windowWillClose:(NSNotification *)note
{
    [self.window endEditingFor:nil];

    [Preferences cleanUpWords];
    [Preferences sync];

    if ([_delegate respondsToSelector:@selector(preferencesDialogWillClose:)]) {
        [_delegate preferencesDialogWillClose:self];
    }
}

@end
