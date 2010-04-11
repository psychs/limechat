// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import <Cocoa/Cocoa.h>
#import "KeyRecorder.h"


#define ThemeDidChangeNotification	@"ThemeDidChangeNotification"


@interface PreferencesController : NSWindowController
{
	id delegate;
	
	IBOutlet KeyRecorder* hotKey;
	
	IBOutlet NSTableView* keywordsTable;
	IBOutlet NSTableView* excludeWordsTable;
	IBOutlet NSTableView* ignoreWordsTable;
	IBOutlet NSArrayController* keywordsArrayController;
	IBOutlet NSArrayController* excludeWordsArrayController;
	IBOutlet NSArrayController* ignoreWordsArrayController;
	IBOutlet NSPopUpButton* transcriptFolderButton;
	IBOutlet NSPopUpButton* themeButton;
	
	NSMutableArray* sounds;
	NSOpenPanel* transcriptFolderOpenPanel;
	NSFont* logFont;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, assign) NSString* fontDisplayName;
@property (nonatomic, assign) CGFloat fontPointSize;
@property (nonatomic, readonly) NSArray* availableSounds;
@property (nonatomic, readonly) NSMutableArray* sounds;

- (void)show;

- (void)onAddKeyword:(id)sender;
- (void)onAddExcludeWord:(id)sender;
- (void)onAddIgnoreWord:(id)sender;

- (void)onTranscriptFolderChanged:(id)sender;
- (void)onLayoutChanged:(id)sender;
- (void)onChangedTheme:(id)sender;
- (void)onOpenThemePath:(id)sender;
- (void)onSelectFont:(id)sender;
- (void)onOverrideFontChanged:(id)sender;
- (void)onChangedTransparency:(id)sender;

@end


@interface NSObject (PreferencesControllerDelegate)
- (void)preferencesDialogWillClose:(PreferencesController*)sender;
@end
