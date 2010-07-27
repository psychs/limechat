// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Foundation/Foundation.h>
#import "ListView.h"


@interface WelcomeDialog : NSWindowController
{
	id delegate;
	NSMutableArray* channels;
	
	IBOutlet NSTextField* nickText;
	IBOutlet NSComboBox* hostCombo;
	IBOutlet ListView* channelTable;
	IBOutlet NSButton* autoConnectCheck;
	IBOutlet NSButton* addChannelButton;
	IBOutlet NSButton* deleteChannelButton;
	IBOutlet NSButton* okButton;
}

@property (nonatomic, assign) id delegate;

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
