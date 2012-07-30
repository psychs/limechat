// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Foundation/Foundation.h>
#import "IRCChannelConfig.h"


@interface ChannelDialog : NSObject
{
    IBOutlet NSWindow* window;
    
    IBOutlet NSTextField* nameText;
    IBOutlet NSTextField* passwordText;
    IBOutlet NSTextField* modeText;
    IBOutlet NSTextField* topicText;
    IBOutlet NSButton* autoJoinCheck;
    IBOutlet NSButton* consoleCheck;
    IBOutlet NSButton* growlCheck;
    IBOutlet NSButton* okButton;
    
    __weak id delegate;
    __weak NSWindow* parentWindow;
    int uid;
    int cid;
    IRCChannelConfig* config;

    BOOL isSheet;
}

@property (nonatomic, weak) id delegate;
@property (nonatomic, readonly) NSWindow* window;
@property (nonatomic, weak) NSWindow* parentWindow;
@property (nonatomic) int uid;
@property (nonatomic) int cid;
@property (nonatomic, strong) IRCChannelConfig* config;

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
