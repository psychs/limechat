// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Cocoa/Cocoa.h>
#import "KeyRecorder.h"


#define ThemeDidChangeNotification	@"ThemeDidChangeNotification"


@interface PreferencesController : NSWindowController
{
	id delegate;
	
	IBOutlet KeyRecorder* hotKey;
	
	IBOutlet NSTableView* keywordsTable;
	IBOutlet NSTableView* excludeWordsTable;
	IBOutlet NSArrayController* keywordsArrayController;
	IBOutlet NSArrayController* excludeWordsArrayController;
	IBOutlet NSPopUpButton* transcriptFolderButton;
	IBOutlet NSPopUpButton* themeButton;
	
	NSMutableArray* sounds;
	NSOpenPanel* transcriptFolderOpenPanel;
	NSFont* logFont;
	NSFont* inputFont;
	BOOL changingLogFont;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, assign) NSString* fontDisplayName;
@property (nonatomic, assign) CGFloat fontPointSize;
@property (nonatomic, assign) NSString* inputFontDisplayName;
@property (nonatomic, assign) CGFloat inputFontPointSize;
@property (nonatomic, readonly) NSArray* availableSounds;
@property (nonatomic, readonly) NSMutableArray* sounds;

- (void)show;

- (void)onAddKeyword:(id)sender;
- (void)onAddExcludeWord:(id)sender;

- (void)onTranscriptFolderChanged:(id)sender;
- (void)onLayoutChanged:(id)sender;
- (void)onChangedTheme:(id)sender;
- (void)onOpenThemePath:(id)sender;
- (void)onSelectFont:(id)sender;
- (void)onInputSelectFont:(id)sender;
- (void)onOverrideFontChanged:(id)sender;
- (void)onChangedTransparency:(id)sender;

@end


@interface NSObject (PreferencesControllerDelegate)
- (void)preferencesDialogWillClose:(PreferencesController*)sender;
@end
