// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Cocoa/Cocoa.h>
#import "MainWindow.h"
#import "ServerTreeView.h"
#import "MemberListView.h"
#import "InputTextField.h"
#import "ChatBox.h"
#import "ThinSplitView.h"
#import "FieldEditorTextView.h"
#import "IRCWorld.h"
#import "InputHistory.h"
#import "MenuController.h"
#import "ViewTheme.h"
#import "NickCompletinStatus.h"
#import "DCCController.h"
#import "NotificationController.h"
#import "WelcomeDialog.h"


@interface AppController : NSObject

@property (nonatomic) IBOutlet MainWindow* window;
@property (nonatomic) IBOutlet ServerTreeView* tree;
@property (nonatomic) IBOutlet NSBox* logBase;
@property (nonatomic) IBOutlet NSBox* consoleBase;
@property (nonatomic) IBOutlet MemberListView* memberList;
@property (nonatomic) IBOutlet InputTextField* text;
@property (nonatomic) IBOutlet ChatBox* chatBox;
@property (nonatomic) IBOutlet NSScrollView* treeScrollView;
@property (nonatomic) IBOutlet NSView* leftTreeBase;
@property (nonatomic) IBOutlet NSView* rightTreeBase;
@property (nonatomic) IBOutlet ThinSplitView* rootSplitter;
@property (nonatomic) IBOutlet ThinSplitView* logSplitter;
@property (nonatomic) IBOutlet ThinSplitView* infoSplitter;
@property (nonatomic) IBOutlet ThinSplitView* treeSplitter;
@property (nonatomic) IBOutlet MenuController* menu;
@property (nonatomic) IBOutlet NSMenuItem* serverMenu;
@property (nonatomic) IBOutlet NSMenuItem* channelMenu;
@property (nonatomic) IBOutlet NSMenu* memberMenu;
@property (nonatomic) IBOutlet NSMenu* treeMenu;
@property (nonatomic) IBOutlet NSMenu* logMenu;
@property (nonatomic) IBOutlet NSMenu* consoleMenu;
@property (nonatomic) IBOutlet NSMenu* urlMenu;
@property (nonatomic) IBOutlet NSMenu* addrMenu;
@property (nonatomic) IBOutlet NSMenu* chanMenu;

@end
