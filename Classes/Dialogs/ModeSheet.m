// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "ModeSheet.h"


@interface ModeSheet (Private)
- (void)updateTextFields;
@end


@implementation ModeSheet

@synthesize mode;
@synthesize channelName;
@synthesize uid;
@synthesize cid;

- (id)init
{
	if (self = [super init]) {
		[NSBundle loadNibNamed:@"ModeSheet" owner:self];
	}
	return self;
}

- (void)dealloc
{
	[mode release];
	[channelName release];
	[super dealloc];
}

- (void)start
{
	[sCheck setState:mode.s];
	[pCheck setState:mode.p];
	[nCheck setState:mode.n];
	[tCheck setState:mode.t];
	[iCheck setState:mode.i];
	[mCheck setState:mode.m];
	[aCheck setState:mode.a];
	[rCheck setState:mode.r];
	[kCheck setState:mode.k.length > 0];
	[lCheck setState:mode.l > 0];
	
	[kText setStringValue:mode.k ?: @""];
	[lText setStringValue:[NSString stringWithFormat:@"%d", mode.l]];
	
	[self updateTextFields];

	if ([channelName hasPrefix:@"!"]) {
		[aCheck setEnabled:YES];
		[rCheck setEnabled:YES];
	}
	else if ([channelName hasPrefix:@"&"]) {
		[aCheck setEnabled:YES];
		[rCheck setEnabled:NO];
	}
	else {
		[aCheck setEnabled:NO];
		[rCheck setEnabled:NO];
	}
	
	[sheet makeFirstResponder:sCheck];
	[self startSheet];
}

- (void)updateTextFields
{
	[kText setEnabled:kCheck.state == NSOnState];
	[lText setEnabled:lCheck.state == NSOnState];
}

- (void)onChangeCheck:(id)sender
{
	[self updateTextFields];
	
	if ([sCheck state] == NSOnState && [pCheck state] == NSOnState) {
		if (sender == sCheck) {
			[pCheck setState:NSOffState];
		}
		else {
			[sCheck setState:NSOffState];
		}
	}
}

- (void)ok:(id)sender
{
	mode.s = [sCheck state] == NSOnState;
	mode.p = [pCheck state] == NSOnState;
	mode.n = [nCheck state] == NSOnState;
	mode.t = [tCheck state] == NSOnState;
	mode.i = [iCheck state] == NSOnState;
	mode.m = [mCheck state] == NSOnState;
	mode.a = [aCheck state] == NSOnState;
	mode.r = [rCheck state] == NSOnState;
	
	if ([kCheck state] == NSOnState) {
		mode.k = [kText stringValue];
	}
	else {
		mode.k = @"";
	}
	
	if ([lCheck state] == NSOnState) {
		mode.l = [[lText stringValue] intValue];
	}
	else {
		mode.l = 0;
	}
	
	if ([delegate respondsToSelector:@selector(modeSheetOnOK:)]) {
		[delegate modeSheetOnOK:self];
	}
	
	[super ok:sender];
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification*)note
{
	if ([delegate respondsToSelector:@selector(modeSheetWillClose:)]) {
		[delegate modeSheetWillClose:self];
	}
}

@end
