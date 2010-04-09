// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import <Foundation/Foundation.h>


@interface WhoisDialog : NSWindowController
{
	id delegate;
	NSString* nick;
	BOOL isOperator;
	
	IBOutlet NSTextField* nickText;
	IBOutlet NSTextField* logInText;
	IBOutlet NSTextField* realnameText;
	IBOutlet NSTextField* addressText;
	IBOutlet NSTextField* serverText;
	IBOutlet NSTextField* serverInfoText;
	IBOutlet NSPopUpButton* channelsCombo;
	IBOutlet NSTextField* awayText;
	IBOutlet NSTextField* idleText;
	IBOutlet NSTextField* signOnText;
	IBOutlet NSButton* joinButton;
	IBOutlet NSButton* closeButton;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, assign) BOOL isOperator;
@property (nonatomic, retain) NSString* nick;

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
