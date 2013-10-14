// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Cocoa/Cocoa.h>
#import "LimeChatApplication.h"
#import "MainWindow.h"
#import "ServerTreeView.h"
#import "InputTextField.h"
#import "ChatBox.h"
#import "FieldEditorTextView.h"
#import "MemberListView.h"
#import "LogController.h"
#import "IRCWorldConfig.h"
#import "IRCClientConfig.h"
#import "IRCChannelConfig.h"
#import "MenuController.h"
#import "ViewTheme.h"
#import "IRCTreeItem.h"
#import "DCCController.h"
#import "NotificationController.h"
#import "IconController.h"


@class AppController;


@interface IRCWorld : NSObject <NSOutlineViewDataSource, NSOutlineViewDelegate, NotificationControllerDelegate>

@property (nonatomic, weak) AppController* app;
@property (nonatomic, weak) MainWindow* window;
@property (nonatomic, weak) id<NotificationController> notifier;
@property (nonatomic, weak) ServerTreeView* tree;
@property (nonatomic, weak) InputTextField* text;
@property (nonatomic, weak) NSBox* logBase;
@property (nonatomic, weak) NSBox* consoleBase;
@property (nonatomic, weak) ChatBox* chatBox;
@property (nonatomic) FieldEditorTextView* fieldEditor;
@property (nonatomic, weak) MemberListView* memberList;
@property (nonatomic, weak) MenuController* menuController;
@property (nonatomic, weak) DCCController* dcc;
@property (nonatomic, weak) ViewTheme* viewTheme;
@property (nonatomic) NSMenu* treeMenu;
@property (nonatomic) NSMenu* logMenu;
@property (nonatomic) NSMenu* consoleMenu;
@property (nonatomic) NSMenu* urlMenu;
@property (nonatomic) NSMenu* addrMenu;
@property (nonatomic) NSMenu* chanMenu;
@property (nonatomic) NSMenu* memberMenu;
@property (nonatomic) LogController* consoleLog;

@property (nonatomic, readonly) NSMutableArray* clients;
@property (nonatomic) IRCTreeItem* selected;
@property (nonatomic, readonly) IRCClient* selectedClient;
@property (nonatomic, readonly) IRCChannel* selectedChannel;

- (void)setup:(IRCWorldConfig*)seed;
- (void)setupTree;
- (void)save;
- (NSMutableDictionary*)dictionaryValue;

- (void)setServerMenuItem:(NSMenuItem*)item;
- (void)setChannelMenuItem:(NSMenuItem*)item;

- (void)onTimer;
- (void)autoConnect:(BOOL)afterWakeUp;
- (void)terminate;
- (void)prepareForSleep;

- (IRCClient*)findClient:(NSString*)name;
- (IRCClient*)findClientById:(int)uid;
- (IRCChannel*)findChannelByClientId:(int)uid channelId:(int)cid;

- (void)select:(id)item;
- (void)selectChannelAt:(int)n;
- (void)selectClientAt:(int)n;
- (void)selectPreviousItem;

- (void)focusInputText;
- (BOOL)inputText:(NSString*)s command:(NSString*)command;

- (void)markAllAsRead;
- (void)markAllScrollbacks;

- (void)updateIcon;
- (void)reloadTree;
- (void)adjustSelection;
- (void)expandClient:(IRCClient*)client;

- (void)updateTitle;
- (void)updateClientTitle:(IRCClient*)client;
- (void)updateChannelTitle:(IRCChannel*)channel;

- (void)sendUserNotification:(UserNotificationType)type title:(NSString*)title desc:(NSString*)desc context:(id)context;

- (void)preferencesChanged;
- (void)reloadTheme;
- (void)changeTextSize:(BOOL)bigger;

- (IRCClient*)createClient:(IRCClientConfig*)seed reload:(BOOL)reload;
- (IRCChannel*)createChannel:(IRCChannelConfig*)seed client:(IRCClient*)client reload:(BOOL)reload adjust:(BOOL)adjust;
- (IRCChannel*)createTalk:(NSString*)nick client:(IRCClient*)client;

- (void)destroyChannel:(IRCChannel*)channel;
- (void)destroyClient:(IRCClient*)client;

- (void)logKeyDown:(NSEvent*)e;
- (void)logDoubleClick:(NSString*)s;

@end
