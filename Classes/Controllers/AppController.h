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
#import "GrowlController.h"
#import "WelcomeDialog.h"


@interface AppController : NSObject
{
	IBOutlet MainWindow* window;
	IBOutlet ServerTreeView* tree;
	IBOutlet NSBox* logBase;
	IBOutlet NSBox* consoleBase;
	IBOutlet MemberListView* memberList;
	IBOutlet InputTextField* text;
	IBOutlet ChatBox* chatBox;
	IBOutlet NSScrollView* treeScrollView;
	IBOutlet NSView* leftTreeBase;
	IBOutlet NSView* rightTreeBase;
	IBOutlet ThinSplitView* rootSplitter;
	IBOutlet ThinSplitView* logSplitter;
	IBOutlet ThinSplitView* infoSplitter;
	IBOutlet ThinSplitView* treeSplitter;
	IBOutlet MenuController* menu;
	IBOutlet NSMenuItem* serverMenu;
	IBOutlet NSMenuItem* channelMenu;
	IBOutlet NSMenu* memberMenu;
	IBOutlet NSMenu* treeMenu;
	IBOutlet NSMenu* logMenu;
	IBOutlet NSMenu* consoleMenu;
	IBOutlet NSMenu* urlMenu;
	IBOutlet NSMenu* addrMenu;
	IBOutlet NSMenu* chanMenu;
	
	WelcomeDialog* welcomeDialog;
	GrowlController* growl;
	DCCController* dcc;
	FieldEditorTextView* fieldEditor;
	IRCWorld* world;
	ViewTheme* viewTheme;
	InputHistory* inputHistory;
	NickCompletinStatus* completionStatus;
	
	BOOL threeColumns;
	BOOL terminating;
}

@end
