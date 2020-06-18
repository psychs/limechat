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

- (IBAction)onAddKeyword:(id)sender;
- (IBAction)onAddExcludeWord:(id)sender;

- (IBAction)onTranscriptFolderChanged:(id)sender;
- (IBAction)onLayoutChanged:(id)sender;
- (IBAction)onChangedTheme:(id)sender;
- (IBAction)onOpenThemePath:(id)sender;
- (IBAction)onSelectFont:(id)sender;
- (IBAction)onInputSelectFont:(id)sender;
- (IBAction)onOverrideFontChanged:(id)sender;
- (IBAction)onChangedTransparency:(id)sender;

@end


@interface NSObject (PreferencesControllerDelegate)
- (void)preferencesDialogWillClose:(PreferencesController*)sender;
@end
