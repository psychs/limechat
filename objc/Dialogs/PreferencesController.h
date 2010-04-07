// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import <Cocoa/Cocoa.h>


@interface PreferencesController : NSWindowController
{
	id delegate;
	
	IBOutlet NSTableView* keywordsTable;
	IBOutlet NSTableView* excludeWordsTable;
	IBOutlet NSTableView* ignoreWordsTable;
	IBOutlet NSArrayController* keywordsArrayController;
	IBOutlet NSArrayController* excludeWordsArrayController;
	IBOutlet NSArrayController* ignoreWordsArrayController;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, assign) int maxLogLines;
@property (nonatomic, assign) NSString* fontDisplayName;
@property (nonatomic, assign) CGFloat fontPointSize;

- (void)show;

- (void)onAddKeyword:(id)sender;
- (void)onAddExcludeWord:(id)sender;
- (void)onAddIgnoreWord:(id)sender;

- (void)onTranscriptFolderChanged:(id)sender;
- (void)onLayoutChanged:(id)sender;
- (void)onChangedTheme:(id)sender;
- (void)onOpenThemePath:(id)sender;
- (void)onSelectFont:(id)sender;
- (void)onChangedTransparency:(id)sender;

@end
