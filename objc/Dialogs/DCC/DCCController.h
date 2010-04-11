// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import <Foundation/Foundation.h>
#import "ThinSplitView.h"
#import "ListView.h"


@class IRCWorld;


@interface DCCController : NSWindowController
{
	id delegate;
	IRCWorld* world;
	NSWindow* mainWindow;
	
	BOOL loaded;
	NSMutableArray* receivers;
	NSMutableArray* senders;
	
	IBOutlet ListView* receiverTable;
	IBOutlet ListView* senderTable;
	IBOutlet ThinSplitView* splitter;
	IBOutlet NSBundle* clearButton;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, assign) IRCWorld* world;
@property (nonatomic, assign) NSWindow* mainWindow;

- (void)show;
- (void)close;
- (void)terminate;

- (void)onClear:(id)sender;

- (void)startReceiver:(id)sender;
- (void)stopReceiver:(id)sender;
- (void)deleteReceiver:(id)sender;
- (void)openReceiver:(id)sender;
- (void)revealReceivedFileInFinder:(id)sender;

- (void)startSender:(id)sender;
- (void)stopSender:(id)sender;
- (void)deleteSender:(id)sender;

@end
