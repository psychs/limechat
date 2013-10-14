// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Cocoa/Cocoa.h>
#import "KeyRecorder.h"


#define ThemeDidChangeNotification	@"ThemeDidChangeNotification"


@interface PreferencesController : NSWindowController

@property (nonatomic, weak) id delegate;
@property (nonatomic) NSString* fontDisplayName;
@property (nonatomic) CGFloat fontPointSize;
@property (nonatomic) NSString* inputFontDisplayName;
@property (nonatomic) CGFloat inputFontPointSize;
@property (nonatomic, readonly) NSArray* availableSounds;
@property (nonatomic, readonly) NSMutableArray* sounds;

@property (nonatomic) IBOutlet KeyRecorder* hotKey;
@property (nonatomic) IBOutlet NSTableView* keywordsTable;
@property (nonatomic) IBOutlet NSTableView* excludeWordsTable;
@property (nonatomic) IBOutlet NSArrayController* keywordsArrayController;
@property (nonatomic) IBOutlet NSArrayController* excludeWordsArrayController;
@property (nonatomic) IBOutlet NSPopUpButton* transcriptFolderButton;
@property (nonatomic) IBOutlet NSPopUpButton* themeButton;
@property (nonatomic) IBOutlet NSTableView* soundsTable;

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
