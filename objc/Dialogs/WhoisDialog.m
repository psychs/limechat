// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "WhoisDialog.h"


@interface WhoisDialog (Private)
- (void)updateNick;
- (void)updateChannels;
@end


@implementation WhoisDialog

@synthesize delegate;
@synthesize isOperator;
@synthesize nick;

- (id)init
{
	if (self = [super init]) {
		[NSBundle loadNibNamed:@"WhoisDialog" owner:self];
	}
	return self;
}

- (void)dealloc
{
	[super dealloc];
}

- (void)setIsOperator:(BOOL)value
{
	isOperator = value;
	[self updateNick];
}

- (void)setNick:(NSString *)value
{
	if (nick != value) {
		[nick release];
		nick = [value retain];
		[self updateNick];
	}
}

- (void)startWithNick:(NSString*)aNick username:(NSString*)username address:(NSString*)address realname:(NSString*)realname
{
	[self setNick:aNick username:username address:address realname:realname];
	[self.window makeFirstResponder:closeButton];
	[self show];
}

- (void)setNick:(NSString*)aNick username:(NSString*)username address:(NSString*)address realname:(NSString*)realname
{
	self.nick = aNick;
	[logInText setStringValue:username];
	[addressText setStringValue:address];
	[realnameText setStringValue:realname];
	[self setAwayMessage:@""];
	[channelsCombo removeAllItems];
	[self updateChannels];
}

- (void)setChannels:(NSArray*)channels
{
	[channelsCombo addItemsWithTitles:channels];
	[self updateChannels];
}

- (void)setServer:(NSString*)server serverInfo:(NSString*)info
{
	[serverText setStringValue:server];
	[serverInfoText setStringValue:info];
}

- (void)setAwayMessage:(NSString*)value
{
	[awayText setStringValue:value];
}

- (void)setIdle:(NSString*)idle signOn:(NSString*)signOn
{
	[idleText setStringValue:idle];
	[signOnText setStringValue:signOn];
}

- (void)updateNick
{
	NSString* s = isOperator ? [nick stringByAppendingString:@" (IRC operator)"] : nick;
	[nickText setStringValue:s];
}

- (void)updateChannels
{
	if ([channelsCombo numberOfItems]) {
		NSMenuItem* sel = [channelsCombo selectedItem];
		if (sel && sel.title.length) {
			[joinButton setEnabled:YES];
			return;
		}
	}
	
	[joinButton setEnabled:NO];
}

- (void)show
{
	[self.window makeKeyAndOrderFront:nil];
}

- (void)close
{
	delegate = nil;
	[self.window close];
}

- (void)onClose:(id)sender
{
	[self.window close];
}

- (void)onTalk:(id)sender
{
	if ([delegate respondsToSelector:@selector(whoisDialogOnTalk:)]) {
		[delegate whoisDialogOnTalk:self];
	}
}

- (void)onUpdate:(id)sender
{
	if ([delegate respondsToSelector:@selector(whoisDialogOnUpdate:)]) {
		[delegate whoisDialogOnUpdate:self];
	}
}

- (void)onJoin:(id)sender
{
	NSMenuItem* sel = [channelsCombo selectedItem];
	if (!sel) return;
	NSString* chname = sel.title;
	if ([chname hasPrefix:@"@"] || [chname hasPrefix:@"+"]) {
		chname = [chname substringFromIndex:1];
	}
	
	if ([delegate respondsToSelector:@selector(whoisDialogOnJoin:channel:)]) {
		[delegate whoisDialogOnJoin:self channel:chname];
	}
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification*)note
{
	if ([delegate respondsToSelector:@selector(whoisDialogWillClose:)]) {
		[delegate whoisDialogWillClose:self];
	}
}

@end
