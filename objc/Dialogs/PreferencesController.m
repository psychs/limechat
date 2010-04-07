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

- (void)onAddHighlightWord:(id)sender
{
}

- (void)onAddDislikeWord:(id)sender
{
}

- (void)onAddIgnoreWord:(id)sender
{
}

- (void)onChangedTransparency:(id)sender
{
}

@end
