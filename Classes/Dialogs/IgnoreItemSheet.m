// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "IgnoreItemSheet.h"


@interface IgnoreItemSheet (Private)
- (void)updateButtons;
- (void)reloadChannelTable;
@end


@implementation IgnoreItemSheet

@synthesize ignore;
@synthesize newItem;

- (id)init
{
	self = [super init];
	if (self) {
		[NSBundle loadNibNamed:@"IgnoreItemSheet" owner:self];
	}
	return self;
}

- (void)dealloc
{
	[ignore release];
	[channels release];
	[super dealloc];
}

- (void)start
{
	//
	// load
	//
	
	if (ignore.nick.length) {
		nickCheck.state = NSOnState;
		[nickPopup selectItemWithTag:ignore.useRegexForNick ? 1 : 0];
		nickText.stringValue = ignore.nick;
	}
	else {
		nickCheck.state = NSOffState;
	}
	
	if (ignore.text.length) {
		messageCheck.state = NSOnState;
		[messagePopup selectItemWithTag:ignore.useRegexForText ? 1 : 0];
		messageText.stringValue = ignore.text;
	}
	else {
		messageCheck.state = NSOffState;
	}
	
	[channels release];
	channels = [ignore.channels mutableCopy];
	if (!channels) {
		channels = [NSMutableArray new];
	}
	[self reloadChannelTable];
	[self updateButtons];
	
	[self startSheet];
}

- (void)reloadChannelTable
{
	[channelTable reloadData];
}

- (void)updateButtons
{
	NSInteger i = [channelTable selectedRow];
	BOOL enabled = (i >= 0);
	[deleteChannelButton setEnabled:enabled];
}

- (void)addChannel:(id)sender
{
	[channels addObject:@""];
	[self reloadChannelTable];

	NSInteger row = [channelTable numberOfRows] - 1;
	[channelTable scrollRowToVisible:row];
	[channelTable editColumn:0 row:row withEvent:nil select:YES];
}

- (void)deleteChannel:(id)sender
{
	NSInteger i = [channelTable selectedRow];
	if (i < 0) return;
	
	[channels removeObjectAtIndex:i];
	
	int count = channels.count;
	if (count) {
		if (count <= i) {
			[channelTable selectItemAtIndex:count - 1];
		}
		else {
			[channelTable selectItemAtIndex:i];
		}
	}
	
	[self reloadChannelTable];
}

- (void)ok:(id)sender
{
	//
	// save
	//
	
	NSString* nick = nickText.stringValue;
	NSString* message = messageText.stringValue;
	
	if (nickCheck.state == NSOnState && nick.length) {
		ignore.nick = nick;
		ignore.useRegexForNick = nickPopup.selectedItem.tag == 1;
	}
	else {
		ignore.nick = nil;
	}
	
	if (messageCheck.state == NSOnState && message.length) {
		ignore.text = message;
		ignore.useRegexForText = messagePopup.selectedItem.tag == 1;
	}
	else {
		ignore.text = nil;
	}
	
	NSMutableSet* channelSet = [NSMutableSet set];
	NSMutableArray* channelAry = [NSMutableArray array];
	for (NSString* e in channels) {
		if (e.length && ![channelSet containsObject:e]) {
			[channelAry addObject:e];
			[channelSet addObject:e];
		}
	}
	[channelAry sortUsingSelector:@selector(caseInsensitiveCompare:)];
	ignore.channels = channelAry;
	
	//
	// call delegate
	//
	
	if ([delegate respondsToSelector:@selector(ignoreItemSheetOnOK:)]) {
		[delegate ignoreItemSheetOnOK:self];
	}
	
	[super ok:sender];
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification*)note
{
	if ([delegate respondsToSelector:@selector(ignoreItemSheetWillClose:)]) {
		[delegate ignoreItemSheetWillClose:self];
	}
}

#pragma mark -
#pragma mark NSTableViwe Delegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)sender
{
	return channels.count;
}

- (id)tableView:(NSTableView *)sender objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
	return [channels objectAtIndex:row];
}

- (void)tableView:(NSTableView *)sender setObjectValue:(id)obj forTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
	[channels replaceObjectAtIndex:row withObject:obj];
}

- (void)tableViewSelectionDidChange:(NSNotification *)note
{
	[self updateButtons];
}

@end
