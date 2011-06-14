// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "ServerDialog.h"
#import "NSWindowHelper.h"
#import "NSLocaleHelper.h"
#import "IRCChannelConfig.h"
#import "IgnoreItem.h"


#define IGNORE_TAB_INDEX	3

#define TABLE_ROW_TYPE		@"row"
#define TABLE_ROW_TYPES		[NSArray arrayWithObject:TABLE_ROW_TYPE]


@interface ServerDialog (Private)
- (void)load;
- (void)save;
- (void)updateConnectionPage;
- (void)updateChannelsPage;
- (void)reloadChannelTable;
- (void)updateIgnoresPage;
- (void)reloadIgnoreTable;
@end


@implementation ServerDialog

@synthesize delegate;
@synthesize parentWindow;
@synthesize uid;
@synthesize config;

- (id)init
{
	self = [super init];
	if (self) {
		[NSBundle loadNibNamed:@"ServerDialog" owner:self];
		
		NSArray* servers = [[self class] availableServers];
		for (NSString* s in servers) {
			[hostCombo addItemWithObjectValue:s];
		}
	}
	return self;
}

- (void)dealloc
{
	[config release];
	[channelSheet release];
	[ignoreSheet release];
	[super dealloc];
}

- (void)startWithIgnoreTab:(BOOL)ignoreTab
{
	if (uid < 0) {
		[self.window setTitle:@"New Server"];
	}
	
	[channelTable setTarget:self];
	[channelTable setDoubleAction:@selector(tableViewDoubleClicked:)];
	[channelTable registerForDraggedTypes:TABLE_ROW_TYPES];
	
	[ignoreTable setTarget:self];
	[ignoreTable setDoubleAction:@selector(tableViewDoubleClicked:)];
	[ignoreTable registerForDraggedTypes:TABLE_ROW_TYPES];
	
	[self load];
	[self updateConnectionPage];
	[self updateChannelsPage];
	[self updateIgnoresPage];
	[self encodingChanged:nil];
	[self proxyChanged:nil];
	[self reloadChannelTable];
	[self reloadIgnoreTable];
	
	if (ignoreTab) {
		[tab selectTabViewItem:[tab tabViewItemAtIndex:IGNORE_TAB_INDEX]];
	}
	
	[self show];
}

- (void)show
{
	if (![self.window isVisible]) {
		[self.window centerOfWindow:parentWindow];
	}
	[self.window makeKeyAndOrderFront:nil];
}

- (void)close
{
	delegate = nil;
	[self.window close];
}

- (void)load
{
	nameText.stringValue = config.name;
	autoConnectCheck.state = config.autoConnect;
	
	hostCombo.stringValue = config.host;
	sslCheck.state = config.useSSL;
	portText.intValue = config.port;

	nickText.stringValue = config.nick;
	passwordText.stringValue = config.password;
	usernameText.stringValue = config.username;
	realNameText.stringValue = config.realName;
	nickPasswordText.stringValue = config.nickPassword;
	saslCheck.state = config.useSASL;
	if (config.altNicks.count) {
		altNicksText.stringValue = [config.altNicks componentsJoinedByString:@" "];
	}
	else {
		altNicksText.stringValue = @"";
	}

	leavingCommentText.stringValue = config.leavingComment;
	userInfoText.stringValue = config.userInfo;

	[encodingCombo selectItemWithTag:config.encoding];
	[fallbackEncodingCombo selectItemWithTag:config.fallbackEncoding];
	
	[proxyCombo selectItemWithTag:config.proxyType];
	proxyHostText.stringValue = config.proxyHost;
	proxyPortText.intValue = config.proxyPort;
	proxyUserText.stringValue = config.proxyUser;
	proxyPasswordText.stringValue = config.proxyPassword;

	loginCommandsText.string = [config.loginCommands componentsJoinedByString:@"\n"];
	invisibleCheck.state = config.invisibleMode;
}

- (void)save
{
	config.name = nameText.stringValue;
	config.autoConnect = autoConnectCheck.state;
	
	config.host = hostCombo.stringValue;
	config.useSSL = sslCheck.state;
	config.port = portText.intValue;
	
	config.nick = nickText.stringValue;
	config.password = passwordText.stringValue;
	config.username = usernameText.stringValue;
	config.realName = realNameText.stringValue;
	config.nickPassword = nickPasswordText.stringValue;
	config.useSASL = saslCheck.state;
	
	NSArray* nicks = [altNicksText.stringValue componentsSeparatedByString:@" "];
	[config.altNicks removeAllObjects];
	for (NSString* s in nicks) {
		if (s.length) {
			[config.altNicks addObject:s];
		}
	}
	
	config.leavingComment = leavingCommentText.stringValue;
	config.userInfo = userInfoText.stringValue;
	
	config.encoding = encodingCombo.selectedTag;
	config.fallbackEncoding = fallbackEncodingCombo.selectedTag;
	
	config.proxyType = proxyCombo.selectedTag;
	config.proxyHost = proxyHostText.stringValue;
	config.proxyPort = proxyPortText.intValue;
	config.proxyUser = proxyUserText.stringValue;
	config.proxyPassword = proxyPasswordText.stringValue;
	
	NSArray* commands = [loginCommandsText.string componentsSeparatedByString:@"\n"];
	[config.loginCommands removeAllObjects];
	for (NSString* s in commands) {
		if (s.length) {
			[config.loginCommands addObject:s];
		}
	}
	
	config.invisibleMode = invisibleCheck.state;
}

- (void)updateConnectionPage
{
	NSString* name = [nameText stringValue];
	NSString* host = [hostCombo stringValue];
	int port = [portText intValue];
	NSString* nick = [nickText stringValue];
	NSString* nickPassword = [nickPasswordText stringValue];
	
	BOOL enabled = name.length && host.length && ![host isEqualToString:@"-"] && port > 0 && nick.length;
	[okButton setEnabled:enabled];
	
	BOOL saslEnabled = nickPassword.length > 0;
	[saslCheck setEnabled:saslEnabled];
}

- (void)updateChannelsPage
{
	NSInteger i = [channelTable selectedRow];
	BOOL enabled = (i >= 0);
	[editChannelButton setEnabled:enabled];
	[deleteChannelButton setEnabled:enabled];
}

- (void)reloadChannelTable
{
	[channelTable reloadData];
}

- (void)updateIgnoresPage
{
	NSInteger i = [ignoreTable selectedRow];
	BOOL enabled = (i >= 0);
	[editIgnoreButton setEnabled:enabled];
	[deleteIgnoreButton setEnabled:enabled];
}

- (void)reloadIgnoreTable
{
	[ignoreTable reloadData];
}

#pragma mark -
#pragma mark Actions

- (void)ok:(id)sender
{
	[self save];
	
	// remove invalid ignores
	NSMutableArray* ignores = config.ignores;
	for (int i=ignores.count-1; i>=0; --i) {
		IgnoreItem* g = [ignores objectAtIndex:i];
		if (!g.isValid) {
			[ignores removeObjectAtIndex:i];
		}
	}
	
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
	int tag = [encodingCombo selectedTag];
	[fallbackEncodingCombo setEnabled:(tag == NSUTF8StringEncoding)];
}

- (void)proxyChanged:(id)sender
{
	int tag = [proxyCombo selectedTag];
	BOOL enabled = (tag == PROXY_SOCKS4 || tag == PROXY_SOCKS5);
	[proxyHostText setEnabled:enabled];
	[proxyPortText setEnabled:enabled];
	[proxyUserText setEnabled:enabled];
	[proxyPasswordText setEnabled:enabled];
	//[sslCheck setEnabled:tag == PROXY_NONE];
}

#pragma mark -
#pragma mark Channel Actions

- (void)addChannel:(id)sender
{
	NSInteger sel = [channelTable selectedRow];
	IRCChannelConfig* conf;
	if (sel < 0) {
		conf = [[IRCChannelConfig new] autorelease];
	}
	else {
		IRCChannelConfig* c = [config.channels objectAtIndex:sel];
		conf = [[c mutableCopy] autorelease];
		conf.name = @"";
	}
	
	[channelSheet release];
	channelSheet = [ChannelDialog new];
	channelSheet.delegate = self;
	channelSheet.parentWindow = self.window;
	channelSheet.config = conf;
	channelSheet.uid = 1;
	channelSheet.cid = -1;
	[channelSheet startSheet];
}

- (void)editChannel:(id)sender
{
	NSInteger sel = [channelTable selectedRow];
	if (sel < 0) return;
	IRCChannelConfig* c = [[[config.channels objectAtIndex:sel] mutableCopy] autorelease];
	
	[channelSheet release];
	channelSheet = [ChannelDialog new];
	channelSheet.delegate = self;
	channelSheet.parentWindow = self.window;
	channelSheet.config = c;
	channelSheet.uid = 1;
	channelSheet.cid = 1;
	[channelSheet startSheet];
}

- (void)channelDialogOnOK:(ChannelDialog*)sender
{
	IRCChannelConfig* conf = sender.config;
	NSString* name = conf.name;
	
	int n = -1;
	int i = 0;
	for (IRCChannelConfig* c in config.channels) {
		if ([c.name isEqualToString:name]) {
			n = i;
			break;
		}
		++i;
	}
	
	if (n < 0) {
		[config.channels addObject:conf];
	}
	else {
		[config.channels replaceObjectAtIndex:n withObject:conf];
	}
	
	[self reloadChannelTable];
}

- (void)channelDialogWillClose:(ChannelDialog*)sender
{
	[channelSheet autorelease];
	channelSheet = nil;
}

- (void)deleteChannel:(id)sender
{
	NSInteger sel = [channelTable selectedRow];
	if (sel < 0) return;
	
	[config.channels removeObjectAtIndex:sel];
	
	int count = config.channels.count;
	if (count) {
		if (count <= sel) {
			[channelTable selectItemAtIndex:count - 1];
		}
		else {
			[channelTable selectItemAtIndex:sel];
		}
	}
	
	[self reloadChannelTable];
}

#pragma mark -
#pragma mark Ignore Actions

- (void)addIgnore:(id)sender
{
	[ignoreSheet release];
	ignoreSheet = [IgnoreItemSheet new];
	ignoreSheet.delegate = self;
	ignoreSheet.window = self.window;
	ignoreSheet.ignore = [[IgnoreItem new] autorelease];
	ignoreSheet.newItem = YES;
	[ignoreSheet start];
}

- (void)editIgnore:(id)sender
{
	NSInteger sel = [ignoreTable selectedRow];
	if (sel < 0) return;
	
	[ignoreSheet release];
	ignoreSheet = [IgnoreItemSheet new];
	ignoreSheet.delegate = self;
	ignoreSheet.window = self.window;
	ignoreSheet.ignore = [config.ignores objectAtIndex:sel];
	[ignoreSheet start];
}

- (void)deleteIgnore:(id)sender
{
	NSInteger sel = [ignoreTable selectedRow];
	if (sel < 0) return;
	
	[config.ignores removeObjectAtIndex:sel];
	
	int count = config.ignores.count;
	if (count) {
		if (count <= sel) {
			[ignoreTable selectItemAtIndex:count - 1];
		}
		else {
			[ignoreTable selectItemAtIndex:sel];
		}
	}
	
	[self reloadIgnoreTable];
}

- (void)ignoreItemSheetOnOK:(IgnoreItemSheet*)sender
{
	if (sender.newItem) {
		[config.ignores addObject:sender.ignore];
	}
	
	[self reloadIgnoreTable];
}

- (void)ignoreItemSheetWillClose:(IgnoreItemSheet*)sender
{
	[ignoreSheet autorelease];
	ignoreSheet = nil;
}

#pragma mark -
#pragma mark NSTableViwe Delegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)sender
{
	if (sender == channelTable) {
		return config.channels.count;
	}
	else {
		return config.ignores.count;
	}
}

- (id)tableView:(NSTableView *)sender objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
	if (sender == channelTable) {
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
	}
	else {
		IgnoreItem* g = [config.ignores objectAtIndex:row];
		NSString* columnId = [column identifier];
		
		if ([columnId isEqualToString:@"nick"]) {
			return g.displayNick;
		}
		else if ([columnId isEqualToString:@"message"]) {
			return g.displayText;
		}
	}
	
	return nil;
}

- (void)tableView:(NSTableView *)sender setObjectValue:(id)obj forTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
	if (sender == channelTable) {
		IRCChannelConfig* c = [config.channels objectAtIndex:row];
		NSString* columnId = [column identifier];
		
		if ([columnId isEqualToString:@"join"]) {
			c.autoJoin = [obj intValue] != 0;
		}
	}
	else {
		;
	}
}

- (void)tableViewSelectionDidChange:(NSNotification *)note
{
	id sender = [note object];
	
	if (sender == channelTable) {
		[self updateChannelsPage];
	}
	else {
		[self updateIgnoresPage];
	}
}

- (void)tableViewDoubleClicked:(id)sender
{
	if (sender == channelTable) {
		[self editChannel:nil];
	}
	else {
		[self editIgnore:nil];
	}
}

- (BOOL)tableView:(NSTableView *)sender writeRowsWithIndexes:(NSIndexSet *)rows toPasteboard:(NSPasteboard *)pboard
{
	if (sender == channelTable) {
		NSArray* ary = [NSArray arrayWithObject:[NSNumber numberWithInt:[rows firstIndex]]];
		[pboard declareTypes:TABLE_ROW_TYPES owner:self];
		[pboard setPropertyList:ary forType:TABLE_ROW_TYPE];
	}
	else {
		;
	}
	return YES;
}

- (NSDragOperation)tableView:(NSTableView *)sender validateDrop:(id < NSDraggingInfo >)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)op
{
	if (sender == channelTable) {
		NSPasteboard* pboard = [info draggingPasteboard];
		if (op == NSTableViewDropAbove && [pboard availableTypeFromArray:TABLE_ROW_TYPES]) {
			return NSDragOperationGeneric;
		}
		else {
			return NSDragOperationNone;
		}
	}
	else {
		return NSDragOperationNone;
	}
}

- (BOOL)tableView:(NSTableView *)sender acceptDrop:(id < NSDraggingInfo >)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)op
{
	if (sender == channelTable) {
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
				[channelTable selectItemAtIndex:sel];
			}
			
			return YES;
		}
	}
	else {
		;
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

#pragma mark -
#pragma mark Servers

+ (NSArray*)availableServers
{
	static NSMutableArray* servers = nil;
	if (!servers) {
		servers = [NSMutableArray new];
		
		if ([NSLocale prefersJapaneseLanguage]) {
			[servers addObject:@"irc.ircnet.ne.jp (IRCnet)"];
			[servers addObject:@"-"];
			[servers addObject:@"irc.friend-chat.jp (Friend)"];
			[servers addObject:@"irc.2ch.net (2ch)"];
			[servers addObject:@"irc.cre.ne.jp (cre)"];
			[servers addObject:@"-"];
			[servers addObject:@"chat.freenode.net (freenode)"];
			[servers addObject:@"eu.undernet.org (Undernet)"];
			[servers addObject:@"irc.quakenet.org (QuakeNet)"];
			[servers addObject:@"chat01.ustream.tv (Ustream)"];
		}
		else {
			[servers addObject:@"chat.freenode.net (freenode)"];
			[servers addObject:@"irc.efnet.net (EFnet)"];
			[servers addObject:@"us.undernet.org (Undernet)"];
			[servers addObject:@"eu.undernet.org (Undernet)"];
			[servers addObject:@"irc.quakenet.org (QuakeNet)"];
			[servers addObject:@"uk.quakenet.org (QuakeNet)"];
			[servers addObject:@"irc.mozilla.org (Mozilla)"];
			[servers addObject:@"chat01.ustream.tv (Ustream)"];
		}
	}
	return servers;
}

@end
