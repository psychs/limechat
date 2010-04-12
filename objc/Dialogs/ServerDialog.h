// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import <Foundation/Foundation.h>
#import "IRCClientConfig.h"
#import "ListView.h"
#import "ChannelDialog.h"


@interface ServerDialog : NSWindowController
{
	id delegate;
	NSWindow* parentWindow;
	int uid;
	IRCClientConfig* config;

	IBOutlet NSTextField* nameText;
	IBOutlet NSButton* autoConnectCheck;
	
	IBOutlet NSComboBox* hostCombo;
	IBOutlet NSButton* sslCheck;
	IBOutlet NSTextField* portText;
	
	IBOutlet NSTextField* nickText;
	IBOutlet NSTextField* passwordText;
	IBOutlet NSTextField* usernameText;
	IBOutlet NSTextField* realNameText;
	IBOutlet NSTextField* nickPasswordText;
	IBOutlet NSTextField* altNicksText;
	
	IBOutlet NSTextField* leavingCommentText;
	IBOutlet NSTextField* userInfoText;
	
	IBOutlet NSPopUpButton* encodingCombo;
	IBOutlet NSPopUpButton* fallbackEncodingCombo;
	
	IBOutlet NSPopUpButton* proxyCombo;
	IBOutlet NSTextField* proxyHostText;
	IBOutlet NSTextField* proxyPortText;
	IBOutlet NSTextField* proxyUserText;
	IBOutlet NSTextField* proxyPasswordText;
	
	IBOutlet ListView* channelTable;
	IBOutlet NSButton* addChannelButton;
	IBOutlet NSButton* editChannelButton;
	IBOutlet NSButton* deleteChannelButton;
	
	IBOutlet NSTextView* loginCommandsText;
	IBOutlet NSButton* invisibleCheck;
	
	IBOutlet NSButton* okButton;
	
	ChannelDialog* channelSheet;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, assign) NSWindow* parentWindow;
@property (nonatomic, assign) int uid;
@property (nonatomic, retain) IRCClientConfig* config;

- (void)start;
- (void)show;
- (void)close;

- (void)ok:(id)sender;
- (void)cancel:(id)sender;

- (void)hostComboChanged:(id)sender;

- (void)encodingChanged:(id)sender;
- (void)proxyChanged:(id)sender;

- (void)addChannel:(id)sender;
- (void)editChannel:(id)sender;
- (void)deleteChannel:(id)sender;

+ (NSArray*)availableServers;

@end


@interface NSObject (ServerDialogDelegate)
- (void)serverDialogOnOK:(ServerDialog*)sender;
- (void)serverDialogWillClose:(ServerDialog*)sender;
@end
