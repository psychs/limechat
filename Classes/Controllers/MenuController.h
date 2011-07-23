// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Cocoa/Cocoa.h>
#import "MainWindow.h"
#import "InputTextField.h"
#import "ServerTreeView.h"
#import "MemberListView.h"
#import "PreferencesController.h"
#import "NickSheet.h"
#import "ModeSheet.h"
#import "TopicSheet.h"
#import "PasteSheet.h"
#import "InviteSheet.h"


@class AppController;
@class IRCWorld;
@class IRCClient;


@interface MenuController : NSObject
{
	IBOutlet NSMenuItem* closeWindowItem;
	IBOutlet NSMenuItem* closeCurrentPanelItem;
	IBOutlet NSMenuItem* checkForUpdateItem;
	
	AppController* app;
	IRCWorld* world;
	MainWindow* window;
	InputTextField* text;
	ServerTreeView* tree;
	MemberListView* memberList;
	
	NSString* pointedUrl;
	NSString* pointedAddress;
	NSString* pointedNick;
	NSString* pointedChannelName;
	
	id sparkleUpdater;
	PreferencesController* preferencesController;
	NSMutableArray* serverDialogs;
	NSMutableArray* channelDialogs;
	NickSheet* nickSheet;
	ModeSheet* modeSheet;
	TopicSheet* topicSheet;
	PasteSheet* pasteSheet;
	InviteSheet* inviteSheet;
	NSOpenPanel* fileSendPanel;
	NSArray* fileSendTargets;
	int fileSendUID;
}

@property (nonatomic, assign) AppController* app;
@property (nonatomic, assign) IRCWorld* world;
@property (nonatomic, assign) MainWindow* window;
@property (nonatomic, assign) InputTextField* text;
@property (nonatomic, assign) ServerTreeView* tree;
@property (nonatomic, assign) MemberListView* memberList;

@property (nonatomic, retain) NSString* pointedUrl;
@property (nonatomic, retain) NSString* pointedAddress;
@property (nonatomic, retain) NSString* pointedNick;
@property (nonatomic, retain) NSString* pointedChannelName;

- (void)setUp;
- (void)terminate;
- (void)startPasteSheetWithContent:(NSString*)content nick:(NSString*)nick uid:(int)uid cid:(int)cid editMode:(BOOL)editMode;
- (void)showServerPropertyDialog:(IRCClient*)client ignore:(BOOL)ignore;

- (void)onPreferences:(id)sender;
- (void)onAutoOp:(id)sender;
- (void)onDcc:(id)sender;
- (void)onMainWindow:(id)sender;
- (void)onHelp:(id)sender;

- (void)onCloseWindow:(id)sender;
- (void)onCloseCurrentPanel:(id)sender;

- (void)onPaste:(id)sender;
- (void)onPasteDialog:(id)sender;
- (void)onUseSelectionForFind:(id)sender;
- (void)onPasteMyAddress:(id)sender;
- (void)onSearchWeb:(id)sender;
- (void)onCopyLogAsHtml:(id)sender;
- (void)onCopyConsoleLogAsHtml:(id)sender;

- (void)onMarkScrollback:(id)sender;
- (void)onClearMark:(id)sender;
- (void)onGoToMark:(id)sender;
- (void)onMarkAllAsRead:(id)sender;
- (void)onMarkAllAsReadAndMarkAllScrollbacks:(id)sender;
- (void)onMakeTextBigger:(id)sender;
- (void)onMakeTextSmaller:(id)sender;
- (void)onReloadTheme:(id)sender;

- (void)onConnect:(id)sender;
- (void)onDisconnect:(id)sender;
- (void)onCancelReconnecting:(id)sender;
- (void)onNick:(id)sender;
- (void)onChannelList:(id)sender;
- (void)onAddServer:(id)sender;
- (void)onCopyServer:(id)sender;
- (void)onDeleteServer:(id)sender;
- (void)onServerProperties:(id)sender;
- (void)onServerAutoOp:(id)sender;

- (void)onJoin:(id)sender;
- (void)onLeave:(id)sender;
- (void)onTopic:(id)sender;
- (void)onMode:(id)sender;
- (void)onAddChannel:(id)sender;
- (void)onDeleteChannel:(id)sender;
- (void)onChannelProperties:(id)sender;
- (void)onChannelAutoOp:(id)sender;

- (void)memberListDoubleClicked:(id)sender;
- (void)onMemberWhois:(id)sender;
- (void)onMemberTalk:(id)sender;
- (void)onMemberGiveOp:(id)sender;
- (void)onMemberDeop:(id)sender;
- (void)onMemberInvite:(id)sender;
- (void)onMemberKick:(id)sender;
- (void)onMemberBan:(id)sender;
- (void)onMemberKickBan:(id)sender;
- (void)onMemberGiveVoice:(id)sender;
- (void)onMemberDevoice:(id)sender;
- (void)onMemberSendFile:(id)sender;
- (void)onMemberPing:(id)sender;
- (void)onMemberTime:(id)sender;
- (void)onMemberVersion:(id)sender;
- (void)onMemberUserInfo:(id)sender;
- (void)onMemberClientInfo:(id)sender;
- (void)onMemberAutoOp:(id)sender;

- (void)onCopyUrl:(id)sender;
- (void)onJoinChannel:(id)sender;
- (void)onCopyAddress:(id)sender;

@end
