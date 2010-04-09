// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import <Foundation/Foundation.h>
#import "IRCChannelConfig.h"


@interface ChannelDialog : NSObject
{
	id delegate;
	NSWindow* parentWindow;
	int uid;
	int cid;
	IRCChannelConfig* config;
	
	IBOutlet NSWindow* window;
	
	IBOutlet NSTextField* nameText;
	IBOutlet NSTextField* passwordText;
	IBOutlet NSTextField* modeText;
	IBOutlet NSTextField* topicText;
	IBOutlet NSButton* autoJoinCheck;
	IBOutlet NSButton* consoleCheck;
	IBOutlet NSButton* growlCheck;
	IBOutlet NSButton* okButton;
	
	BOOL isSheet;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, readonly) NSWindow* window;
@property (nonatomic, assign) NSWindow* parentWindow;
@property (nonatomic, assign) int uid;
@property (nonatomic, assign) int cid;
@property (nonatomic, retain) IRCChannelConfig* config;

- (void)start;
- (void)startSheet;
- (void)show;
- (void)close;

- (void)ok:(id)sender;
- (void)cancel:(id)sender;

@end


@interface NSObject (ChannelDialogDelegate)
- (void)channelDialogOnOK:(ChannelDialog*)sender;
- (void)channelDialogWillClose:(ChannelDialog*)sender;
@end
