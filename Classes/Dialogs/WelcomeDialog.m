// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "WelcomeDialog.h"
#import "ServerDialog.h"
#import "OnigRegexp.h"
#import "NSStringHelper.h"


@interface WelcomeDialog (Private)
- (void)updateOKButton;
- (void)tableViewSelectionIsChanging:(NSNotification *)note;
@end


@implementation WelcomeDialog

@synthesize delegate;

- (id)init
{
	self = [super init];
	if (self) {
		[NSBundle loadNibNamed:@"WelcomeDialog" owner:self];
		
		channels = [NSMutableArray new];
		
		NSArray* servers = [ServerDialog availableServers];
		for (NSString* s in servers) {
			[hostCombo addItemWithObjectValue:s];
		}
	}
	return self;
}

- (void)dealloc
{
	[channels release];
	channelTable.delegate = nil;
	channelTable.dataSource = nil;
	[super dealloc];
}

- (void)show
{
	[self tableViewSelectionIsChanging:nil];
	[self updateOKButton];
	
	if (![self.window isVisible]) {
		[self.window center];
		
		NSString* nick = NSUserName();
		nick = [nick stringByReplacingOccurrencesOfString:@" " withString:@""];
		
		OnigRegexp* nickRegex = [OnigRegexp compile:@"[a-zA-Z][-_a-zA-Z0-9]*"];
		OnigResult* result = [nickRegex match:nick];
		if (result) {
			nickText.stringValue = [nick substringWithRange:result.bodyRange];
		}
	}
	
	[self.window makeKeyAndOrderFront:nil];
}

- (void)close
{
	delegate = nil;
	[self.window close];
}

- (void)onOK:(id)sender
{
	[self.window endEditingFor:nil];
	
	/*
	NSText* fieldEditor = [self.window fieldEditor:NO forObject:channelTable];
	if (fieldEditor) {
		[[channelTable cell] endEditing:fieldEditor];
		NSInteger n = [channelTable editedRow];
		if (n != NSNotFound) {
			NSString* s = [[[fieldEditor string] copy] autorelease];
			if (n < channels.count) {
				[channels replaceObjectAtIndex:n withObject:s];
			}
		}
	}
	 */
	
	NSMutableSet* set = [NSMutableSet set];
	NSMutableArray* chans = [NSMutableArray array];
	
	for (NSString* s in channels) {
		if (s.length > 0) {
			if (![s isChannelName]) {
				s = [@"#" stringByAppendingString:s];
			}
			
			if (![set containsObject:s]) {
				[chans addObject:s];
				[set addObject:s];
			}
		}
	}
	
	NSMutableDictionary* dic = [NSMutableDictionary dictionary];
	[dic setObject:nickText.stringValue forKey:@"nick"];
	[dic setObject:hostCombo.stringValue forKey:@"host"];
	[dic setObject:chans forKey:@"channels"];
	[dic setObject:[NSNumber numberWithBool:autoConnectCheck.state] forKey:@"autoConnect"];
	
	if ([delegate respondsToSelector:@selector(welcomeDialog:onOK:)]) {
		[delegate welcomeDialog:self onOK:dic];
	}
	
	[self.window close];
}

- (void)onCancel:(id)sender
{
	[self.window close];
}

- (void)onAddChannel:(id)sender
{
	[channels addObject:@""];
	[channelTable reloadData];
	int row = channels.count - 1;
	[channelTable selectItemAtIndex:row];
	[channelTable editColumn:0 row:row withEvent:nil select:YES];
}

- (void)onDeleteChannel:(id)sender
{
	NSInteger n = [channelTable selectedRow];
	if (n >= 0) {
		[channels removeObjectAtIndex:n];
		[channelTable reloadData];
		int count = channels.count;
		if (count <= n) n = count - 1;
		if (n >= 0) {
			[channelTable selectItemAtIndex:n];
		}
		[self tableViewSelectionIsChanging:nil];
	}
}

- (void)controlTextDidChange:(NSNotification*)note
{
	[self updateOKButton];
}

- (void)onHostComboChanged:(id)sender
{
	[self updateOKButton];
}

- (void)updateOKButton
{
	NSString* nick = nickText.stringValue;
	NSString* host = hostCombo.stringValue;
	[okButton setEnabled:nick.length > 0 && host.length > 0];
}

#pragma mark -
#pragma mark NSTableViwe Delegate

- (void)textDidEndEditing:(NSNotification*)note
{
	NSInteger n = [channelTable editedRow];
	if (n >= 0) {
		NSString* s = [[[[[note object] textStorage] string] copy] autorelease];
		[channels replaceObjectAtIndex:n withObject:s];
		[channelTable reloadData];
		[channelTable selectItemAtIndex:n];
		[self tableViewSelectionIsChanging:nil];
	}
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)sender
{
	return channels.count;
}

- (id)tableView:(NSTableView *)sender objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
	return [channels objectAtIndex:row];
}

- (void)tableViewSelectionIsChanging:(NSNotification *)note
{
	[deleteChannelButton setEnabled:[channelTable selectedRow] >= 0];
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification*)note
{
	if ([delegate respondsToSelector:@selector(welcomeDialogWillClose:)]) {
		[delegate welcomeDialogWillClose:self];
	}
}

@end
