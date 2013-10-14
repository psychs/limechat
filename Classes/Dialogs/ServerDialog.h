// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Foundation/Foundation.h>
#import "IRCClientConfig.h"
#import "ListView.h"
#import "ChannelDialog.h"
#import "IgnoreItemSheet.h"


@interface ServerDialog : NSWindowController

@property (nonatomic, weak) id delegate;
@property (nonatomic, weak) NSWindow* parentWindow;
@property (nonatomic) int uid;
@property (nonatomic) IRCClientConfig* config;

@property (nonatomic) IBOutlet NSTabView* tab;

@property (nonatomic) IBOutlet NSTextField* nameText;
@property (nonatomic) IBOutlet NSButton* autoConnectCheck;

@property (nonatomic) IBOutlet NSComboBox* hostCombo;
@property (nonatomic) IBOutlet NSButton* sslCheck;
@property (nonatomic) IBOutlet NSTextField* portText;

@property (nonatomic) IBOutlet NSTextField* nickText;
@property (nonatomic) IBOutlet NSTextField* passwordText;
@property (nonatomic) IBOutlet NSTextField* usernameText;
@property (nonatomic) IBOutlet NSTextField* realNameText;
@property (nonatomic) IBOutlet NSTextField* nickPasswordText;
@property (nonatomic) IBOutlet NSButton* saslCheck;
@property (nonatomic) IBOutlet NSTextField* altNicksText;

@property (nonatomic) IBOutlet NSTextField* leavingCommentText;
@property (nonatomic) IBOutlet NSTextField* userInfoText;

@property (nonatomic) IBOutlet NSPopUpButton* encodingCombo;
@property (nonatomic) IBOutlet NSPopUpButton* fallbackEncodingCombo;

@property (nonatomic) IBOutlet NSPopUpButton* proxyCombo;
@property (nonatomic) IBOutlet NSTextField* proxyHostText;
@property (nonatomic) IBOutlet NSTextField* proxyPortText;
@property (nonatomic) IBOutlet NSTextField* proxyUserText;
@property (nonatomic) IBOutlet NSTextField* proxyPasswordText;

@property (nonatomic) IBOutlet ListView* channelTable;
@property (nonatomic) IBOutlet NSButton* addChannelButton;
@property (nonatomic) IBOutlet NSButton* editChannelButton;
@property (nonatomic) IBOutlet NSButton* deleteChannelButton;

@property (nonatomic) IBOutlet NSTextView* loginCommandsText;
@property (nonatomic) IBOutlet NSButton* invisibleCheck;

@property (nonatomic) IBOutlet ListView* ignoreTable;
@property (nonatomic) IBOutlet NSButton* addIgnoreButton;
@property (nonatomic) IBOutlet NSButton* editIgnoreButton;
@property (nonatomic) IBOutlet NSButton* deleteIgnoreButton;

@property (nonatomic) IBOutlet NSButton* okButton;

- (void)startWithIgnoreTab:(BOOL)ignoreTab;
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

- (void)addIgnore:(id)sender;
- (void)editIgnore:(id)sender;
- (void)deleteIgnore:(id)sender;

+ (NSArray*)availableServers;

@end


@interface NSObject (ServerDialogDelegate)
- (void)serverDialogOnOK:(ServerDialog*)sender;
- (void)serverDialogWillClose:(ServerDialog*)sender;
@end
