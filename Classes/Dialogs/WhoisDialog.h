// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Foundation/Foundation.h>


@interface WhoisDialog : NSWindowController

@property (nonatomic, weak) id delegate;
@property (nonatomic) BOOL isOperator;
@property (nonatomic) NSString* nick;

@property (nonatomic) IBOutlet NSTextField* nickText;
@property (nonatomic) IBOutlet NSTextField* logInText;
@property (nonatomic) IBOutlet NSTextField* realnameText;
@property (nonatomic) IBOutlet NSTextField* addressText;
@property (nonatomic) IBOutlet NSTextField* serverText;
@property (nonatomic) IBOutlet NSTextField* serverInfoText;
@property (nonatomic) IBOutlet NSPopUpButton* channelsCombo;
@property (nonatomic) IBOutlet NSTextField* awayText;
@property (nonatomic) IBOutlet NSTextField* idleText;
@property (nonatomic) IBOutlet NSTextField* signOnText;
@property (nonatomic) IBOutlet NSButton* joinButton;
@property (nonatomic) IBOutlet NSButton* closeButton;

- (void)show;
- (void)close;

- (void)startWithNick:(NSString*)nick username:(NSString*)username address:(NSString*)address realname:(NSString*)realname;

- (void)setNick:(NSString*)nick username:(NSString*)username address:(NSString*)address realname:(NSString*)realname;
- (void)setChannels:(NSArray*)channels;
- (void)setServer:(NSString*)server serverInfo:(NSString*)info;
- (void)setAwayMessage:(NSString*)value;
- (void)setIdle:(NSString*)idle signOn:(NSString*)signOn;

- (void)onClose:(id)sender;
- (void)onTalk:(id)sender;
- (void)onUpdate:(id)sender;
- (void)onJoin:(id)sender;

@end


@interface NSObject (WhoisDialogDelegate)
- (void)whoisDialogOnTalk:(WhoisDialog*)sender;
- (void)whoisDialogOnUpdate:(WhoisDialog*)sender;
- (void)whoisDialogOnJoin:(WhoisDialog*)sender channel:(NSString*)channel;
- (void)whoisDialogWillClose:(WhoisDialog*)sender;
@end
