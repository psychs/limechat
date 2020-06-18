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

- (IBAction)onOK:(id)sender;
- (IBAction)onCancel:(id)sender;
- (IBAction)onAddChannel:(id)sender;
- (IBAction)onDeleteChannel:(id)sender;

- (IBAction)onHostComboChanged:(id)sender;

@end


@interface NSObject (WelcomeDialogDelegate)
- (void)welcomeDialog:(WelcomeDialog*)sender onOK:(NSDictionary*)config;
- (void)welcomeDialogWillClose:(WelcomeDialog*)sender;
@end
