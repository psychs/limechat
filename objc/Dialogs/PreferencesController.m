// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "PreferencesController.h"


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
	[super dealloc];
}

#pragma mark -
#pragma mark Utilities

- (void)show
{
	[self.window makeKeyAndOrderFront:nil];
}

#pragma mark -
#pragma mark KVC Properties

- (void)setDccLastPort:(int)value
{
}

- (int)dccLastPort
{
	return 1196;
}

- (void)setMaxLogLines:(int)value
{
}

- (int)maxLogLines
{
	return 300;
}

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

- (void)onTranscriptFolderChanged:(id)sender
{
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
