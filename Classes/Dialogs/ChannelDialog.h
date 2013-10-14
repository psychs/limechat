// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Foundation/Foundation.h>
#import "IRCChannelConfig.h"


@interface ChannelDialog : NSObject

@property (nonatomic, weak) id delegate;
@property (nonatomic, weak) NSWindow* parentWindow;
@property (nonatomic) int uid;
@property (nonatomic) int cid;
@property (nonatomic) IRCChannelConfig* config;

@property (nonatomic) IBOutlet NSWindow* window;
@property (nonatomic) IBOutlet NSTextField* nameText;
@property (nonatomic) IBOutlet NSTextField* passwordText;
@property (nonatomic) IBOutlet NSTextField* modeText;
@property (nonatomic) IBOutlet NSTextField* topicText;
@property (nonatomic) IBOutlet NSButton* autoJoinCheck;
@property (nonatomic) IBOutlet NSButton* consoleCheck;
@property (nonatomic) IBOutlet NSButton* notifyCheck;
@property (nonatomic) IBOutlet NSButton* okButton;

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
