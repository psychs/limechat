// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "ServerDialog.h"
#import "NSWindowHelper.h"
#import "NSLocaleHelper.h"


@interface ServerDialog (Private)
- (void)load;
- (void)save;
- (void)updateConnectionPage;
- (void)updateChannelsPage;
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
	
	[self load];
	[self updateConnectionPage];
	[self updateChannelsPage];
	[self encodingChanged:nil];
	[self proxyChanged:nil];
	
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
	int i = [channelsTable selectedRow];
	BOOL enabled = (i >= 0);
	[editChannelButton setEnabled:enabled];
	[deleteChannelButton setEnabled:enabled];
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
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification*)note
{
	if ([delegate respondsToSelector:@selector(serverDialogWillClose:)]) {
		[delegate serverDialogWillClose:self];
	}
}

@end
