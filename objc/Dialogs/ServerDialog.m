// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "ServerDialog.h"
#import "NSWindowHelper.h"
#import "NSLocaleHelper.h"
#import "IRCChannelConfig.h"


#define TABLE_ROW_TYPE		@"row"
#define TABLE_ROW_TYPES		[NSArray arrayWithObject:TABLE_ROW_TYPE]


@interface ServerDialog (Private)
- (void)load;
- (void)save;
- (void)updateConnectionPage;
- (void)updateChannelsPage;
- (void)reloadChannelTable;
@end


@implementation ServerDialog

@synthesize delegate;
@synthesize parentWindow;
@synthesize uid;
@synthesize config;

- (id)init
{
	if (self = [super init]) {
		[NSBundle loadNibNamed:@"ServerDialog" owner:self];
		
		if ([NSLocale prefersJapaneseLanguage]) {
			[hostCombo addItemWithObjectValue:@"irc.ircnet.ne.jp (IRCnet)"];
			[hostCombo addItemWithObjectValue:@"-"];
			[hostCombo addItemWithObjectValue:@"irc.friend-chat.jp (Friend)"];
			[hostCombo addItemWithObjectValue:@"irc.2ch.net (2ch)"];
			[hostCombo addItemWithObjectValue:@"irc.cre.ne.jp (cre)"];
			[hostCombo addItemWithObjectValue:@"-"];
			[hostCombo addItemWithObjectValue:@"chat.freenode.net (freenode)"];
			[hostCombo addItemWithObjectValue:@"eu.undernet.org (Undernet)"];
			[hostCombo addItemWithObjectValue:@"irc.quakenet.org (QuakeNet)"];
			[hostCombo addItemWithObjectValue:@"chat1.ustream.tv (Ustream)"];
		}
		else {
			[hostCombo addItemWithObjectValue:@"chat.freenode.net (freenode)"];
			[hostCombo addItemWithObjectValue:@"irc.efnet.net (EFnet)"];
			[hostCombo addItemWithObjectValue:@"irc.us.ircnet.net (IRCnet)"];
			[hostCombo addItemWithObjectValue:@"irc.fr.ircnet.net (IRCnet)"];
			[hostCombo addItemWithObjectValue:@"us.undernet.org (Undernet)"];
			[hostCombo addItemWithObjectValue:@"eu.undernet.org (Undernet)"];
			[hostCombo addItemWithObjectValue:@"irc.quakenet.org (QuakeNet)"];
			[hostCombo addItemWithObjectValue:@"uk.quakenet.org (QuakeNet)"];
			[hostCombo addItemWithObjectValue:@"irc.mozilla.org (Mozilla)"];
			[hostCombo addItemWithObjectValue:@"chat1.ustream.tv (Ustream)"];
		}
	}
	return self;
}

- (void)dealloc
{
	[config release];
	[super dealloc];
}

- (void)start
{
	if (uid < 0) {
		[self.window setTitle:@"New Server"];
	}
	
	[channelTable setTarget:self];
	[channelTable setDoubleAction:@selector(tableViewDoubleClicked:)];
	[channelTable registerForDraggedTypes:TABLE_ROW_TYPES];

	[self load];
	[self updateConnectionPage];
	[self updateChannelsPage];
	[self encodingChanged:nil];
	[self proxyChanged:nil];
	[self reloadChannelTable];
	
	[self show];
}

- (void)show
{
	if (![self.window isVisible]) {
		[self.window centerOfWindow:parentWindow];
	}
	[self.window makeKeyAndOrderFront:nil];
}

- (void)load
{
	[nameText setStringValue:config.name];
	[autoConnectCheck setState:config.autoConnect];
	
	[hostCombo setStringValue:config.host];
	[sslCheck setState:config.useSSL];
	[portText setIntValue:config.port];
	
	[nickText setStringValue:config.nick];
	[passwordText setStringValue:config.password];
	[usernameText setStringValue:config.username];
	[realNameText setStringValue:config.realName];
	[nickPasswordText setStringValue:config.nickPassword];
	if (config.altNicks.count) {
		[altNicksText setStringValue:[config.altNicks componentsJoinedByString:@" "]];
	}
	else {
		[altNicksText setStringValue:@""];
	}

	[leavingCommentText setStringValue:config.leavingComment];
	[userInfoText setStringValue:config.userInfo];

	[encodingCombo selectItemWithTag:config.encoding];
	[fallbackEncodingCombo selectItemWithTag:config.fallbackEncoding];
	
	[proxyCombo selectItemWithTag:config.proxyType];
	[proxyHostText setStringValue:config.proxyHost];
	[proxyPortText setIntValue:config.proxyPort];
	[proxyUserText setStringValue:config.proxyUser];
	[proxyPasswordText setStringValue:config.proxyPassword];
	
	//IBOutlet ListView* channelsTable;

	[loginCommandsText setString:[config.loginCommands componentsJoinedByString:@"\n"]];
	[invisibleCheck setState:config.invisibleMode];
}

- (void)save
{
}

- (void)updateConnectionPage
{
	NSString* name = [nameText stringValue];
	NSString* host = [hostCombo stringValue];
	int port = [portText intValue];
	NSString* nick = [nickText stringValue];
	
	BOOL enabled = name.length > 0 && host.length > 0 && ![host isEqualToString:@"-"] && port > 0 && nick.length > 0;
	[okButton setEnabled:enabled];
}

- (void)updateChannelsPage
{
	int i = [channelTable selectedRow];
	BOOL enabled = (i >= 0);
	[editChannelButton setEnabled:enabled];
	[deleteChannelButton setEnabled:enabled];
}

- (void)reloadChannelTable
{
	[channelTable reloadData];
}

#pragma mark -
#pragma mark Actions

- (void)ok:(id)sender
{
	[self save];
	
	if ([delegate respondsToSelector:@selector(serverDialogOnOK:)]) {
		[delegate serverDialogOnOK:self];
	}
	
	[self.window close];
}

- (void)cancel:(id)sender
{
	[self.window close];
}

- (void)controlTextDidChange:(NSNotification*)note
{
	[self updateConnectionPage];
}

- (void)hostComboChanged:(id)sender
{
	[self updateConnectionPage];
}

- (void)encodingChanged:(id)sender
{
	int tag = [[encodingCombo selectedItem] tag];
	[fallbackEncodingCombo setEnabled:(tag == NSUTF8StringEncoding)];
}

- (void)proxyChanged:(id)sender
{
	int tag = [[proxyCombo selectedItem] tag];
	BOOL enabled = (tag == PROXY_SOCKS4 || tag == PROXY_SOCKS5);
	[proxyHostText setEnabled:enabled];
	[proxyPortText setEnabled:enabled];
	[proxyUserText setEnabled:enabled];
	[proxyPasswordText setEnabled:enabled];
	[sslCheck setEnabled:tag == PROXY_NONE];
}

- (void)addChannel:(id)sender
{
	LOG_METHOD
}

- (void)deleteChannel:(id)sender
{
	LOG_METHOD
}

- (void)editChannel:(id)sender
{
	LOG_METHOD
}

#pragma mark -
#pragma mark NSTableViwe Delegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)sender
{
	return config.channels.count;
}

- (id)tableView:(NSTableView *)sender objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
	IRCChannelConfig* c = [config.channels objectAtIndex:row];
	NSString* columnId = [column identifier];
	
	if ([columnId isEqualToString:@"name"]) {
		return c.name;
	}
	else if ([columnId isEqualToString:@"pass"]) {
		return c.password;
	}
	else if ([columnId isEqualToString:@"join"]) {
		return [NSNumber numberWithBool:c.autoJoin];
	}
	
	return nil;
}

- (void)tableView:(NSTableView *)sender setObjectValue:(id)obj forTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
	IRCChannelConfig* c = [config.channels objectAtIndex:row];
	NSString* columnId = [column identifier];
	
	if ([columnId isEqualToString:@"join"]) {
		c.autoJoin = [obj intValue] != 0;
	}
}

- (void)tableViewSelectionDidChange:(NSNotification *)note
{
	[self updateChannelsPage];
}

- (void)tableViewDoubleClicked:(id)sender
{
	[self editChannel:nil];
}

- (BOOL)tableView:(NSTableView *)sender writeRowsWithIndexes:(NSIndexSet *)rows toPasteboard:(NSPasteboard *)pboard
{
	NSArray* ary = [NSArray arrayWithObject:[NSNumber numberWithInt:[rows firstIndex]]];
	
	[pboard declareTypes:TABLE_ROW_TYPES owner:self];
	[pboard setPropertyList:ary forType:TABLE_ROW_TYPE];
	return YES;
}

- (NSDragOperation)tableView:(NSTableView *)sender validateDrop:(id < NSDraggingInfo >)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)op
{
	NSPasteboard* pboard = [info draggingPasteboard];
	if (op == NSTableViewDropAbove && [pboard availableTypeFromArray:TABLE_ROW_TYPES]) {
		return NSDragOperationGeneric;
	}
	else {
		return NSDragOperationNone;
	}
}

- (BOOL)tableView:(NSTableView *)sender acceptDrop:(id < NSDraggingInfo >)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)op
{
	NSPasteboard* pboard = [info draggingPasteboard];
	if (op == NSTableViewDropAbove && [pboard availableTypeFromArray:TABLE_ROW_TYPES]) {
		NSArray* selectedRows = [pboard propertyListForType:TABLE_ROW_TYPE];
		int sel = [[selectedRows objectAtIndex:0] intValue];
		
		NSMutableArray* ary = config.channels;
		IRCChannelConfig* target = [ary objectAtIndex:sel];
		[[target retain] autorelease];

		NSMutableArray* low = [[[ary subarrayWithRange:NSMakeRange(0, row)] mutableCopy] autorelease];
		NSMutableArray* high = [[[ary subarrayWithRange:NSMakeRange(row, ary.count - row)] mutableCopy] autorelease];
		
		[low removeObjectIdenticalTo:target];
		[high removeObjectIdenticalTo:target];
		
		[ary removeAllObjects];
		
		[ary addObjectsFromArray:low];
		[ary addObject:target];
		[ary addObjectsFromArray:high];
		
		[self reloadChannelTable];
		
		sel = [ary indexOfObjectIdenticalTo:target];
		if (0 <= sel) {
			[channelTable select:sel];
		}
		
		return YES;
	}
	return NO;
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification*)note
{
	[channelTable unregisterDraggedTypes];
	
	if ([delegate respondsToSelector:@selector(serverDialogWillClose:)]) {
		[delegate serverDialogWillClose:self];
	}
}

@end
