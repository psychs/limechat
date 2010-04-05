// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import <Cocoa/Cocoa.h>
#import "LimeChatApplication.h"
#import "MainWindow.h"
#import "ServerTreeView.h"
#import "InputTextField.h"
#import "ChatBox.h"
#import "FieldEditorTextView.h"
#import "MemberListView.h"


@interface IRCWorld : NSObject
{
	LimeChatApplication* app;
	MainWindow* window;
	ServerTreeView* tree;
	InputTextField* text;
	NSView* logBase;
	NSView* consoleBase;
	ChatBox* chatBox;
	FieldEditorTextView* fieldEditor;
	MemberListView* memberList;
	id menuController;
	id dcc;
	id viewTheme;
	NSMenu* serverMenu;
	NSMenu* channelMenu;
	NSMenu* treeMenu;
	NSMenu* logMenu;
	NSMenu* consoleMenu;
	NSMenu* urlMenu;
	NSMenu* addrMenu;
	NSMenu* chanMenu;
	NSMenu* memberMenu;
	
	NSMutableArray* clients;
}

@property (nonatomic, assign) LimeChatApplication* app;
@property (nonatomic, assign) MainWindow* window;
@property (nonatomic, assign) ServerTreeView* tree;
@property (nonatomic, assign) InputTextField* text;
@property (nonatomic, assign) NSView* logBase;
@property (nonatomic, assign) NSView* consoleBase;
@property (nonatomic, assign) ChatBox* chatBox;
@property (nonatomic, assign) FieldEditorTextView* fieldEditor;
@property (nonatomic, assign) MemberListView* memberList;
@property (nonatomic, assign) id menuController;
@property (nonatomic, assign) id dcc;
@property (nonatomic, assign) id viewTheme;
@property (nonatomic, assign) NSMenu* serverMenu;
@property (nonatomic, assign) NSMenu* channelMenu;
@property (nonatomic, assign) NSMenu* treeMenu;
@property (nonatomic, assign) NSMenu* logMenu;
@property (nonatomic, assign) NSMenu* consoleMenu;
@property (nonatomic, assign) NSMenu* urlMenu;
@property (nonatomic, assign) NSMenu* addrMenu;
@property (nonatomic, assign) NSMenu* chanMenu;
@property (nonatomic, assign) NSMenu* memberMenu;

@property (nonatomic, readonly) NSMutableArray* clients;
@property (nonatomic, readonly) id selected;

- (void)setup:(id)config;
- (void)setupTree;
- (void)onTimer;
- (void)autoConnect;

@end
