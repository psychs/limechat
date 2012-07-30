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
{
    __weak AppController* app;
    __weak MainWindow* window;
    __weak id<NotificationController> notifier;
    IconController* icon;
    __weak ServerTreeView* tree;
    __weak InputTextField* text;
    __weak NSBox* logBase;
    __weak NSBox* consoleBase;
    __weak ChatBox* chatBox;
    __weak FieldEditorTextView* fieldEditor;
    __weak MemberListView* memberList;
    __weak MenuController* menuController;
    __weak DCCController* dcc;
    __weak ViewTheme* viewTheme;
    __weak NSMenu* serverMenu;
    __weak NSMenu* channelMenu;
    __weak NSMenu* treeMenu;
    __weak NSMenu* logMenu;
    __weak NSMenu* consoleMenu;
    __weak NSMenu* urlMenu;
    __weak NSMenu* addrMenu;
    __weak NSMenu* chanMenu;
    __weak NSMenu* memberMenu;

    LogController* consoleLog;
    LogController* dummyLog;

    IRCWorldConfig* config;
    NSMutableArray* clients;

    int itemId;
    BOOL reloadingTree;
    IRCTreeItem* selected;

    int previousSelectedClientId;
    int previousSelectedChannelId;
}

@property (nonatomic, weak) AppController* app;
@property (nonatomic, weak) MainWindow* window;
@property (nonatomic, weak) id<NotificationController> notifier;
@property (nonatomic, weak) ServerTreeView* tree;
@property (nonatomic, weak) InputTextField* text;
@property (nonatomic, weak) NSBox* logBase;
@property (nonatomic, weak) NSBox* consoleBase;
@property (nonatomic, weak) ChatBox* chatBox;
@property (nonatomic, weak) FieldEditorTextView* fieldEditor;
@property (nonatomic, weak) MemberListView* memberList;
@property (nonatomic, weak) MenuController* menuController;
@property (nonatomic, weak) DCCController* dcc;
@property (nonatomic, weak) ViewTheme* viewTheme;
@property (nonatomic, weak) NSMenu* treeMenu;
@property (nonatomic, weak) NSMenu* logMenu;
@property (nonatomic, weak) NSMenu* consoleMenu;
@property (nonatomic, weak) NSMenu* urlMenu;
@property (nonatomic, weak) NSMenu* addrMenu;
@property (nonatomic, weak) NSMenu* chanMenu;
@property (nonatomic, weak) NSMenu* memberMenu;
@property (nonatomic, weak) LogController* consoleLog;

@property (nonatomic, readonly) NSMutableArray* clients;
@property (nonatomic, strong) IRCTreeItem* selected;
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
