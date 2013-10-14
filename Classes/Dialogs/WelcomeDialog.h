// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Foundation/Foundation.h>
#import "ListView.h"


@interface WelcomeDialog : NSWindowController

@property (nonatomic, weak) id delegate;

@property (nonatomic) IBOutlet NSTextField* nickText;
@property (nonatomic) IBOutlet NSComboBox* hostCombo;
@property (nonatomic) IBOutlet ListView* channelTable;
@property (nonatomic) IBOutlet NSButton* autoConnectCheck;
@property (nonatomic) IBOutlet NSButton* addChannelButton;
@property (nonatomic) IBOutlet NSButton* deleteChannelButton;
@property (nonatomic) IBOutlet NSButton* okButton;

- (void)show;
- (void)close;

- (void)onOK:(id)sender;
- (void)onCancel:(id)sender;
- (void)onAddChannel:(id)sender;
- (void)onDeleteChannel:(id)sender;

- (void)onHostComboChanged:(id)sender;

@end


@interface NSObject (WelcomeDialogDelegate)
- (void)welcomeDialog:(WelcomeDialog*)sender onOK:(NSDictionary*)config;
- (void)welcomeDialogWillClose:(WelcomeDialog*)sender;
@end
