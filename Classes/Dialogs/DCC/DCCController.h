// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Foundation/Foundation.h>
#import "ThinSplitView.h"
#import "ListView.h"
#import "Timer.h"


@class IRCWorld;
@class IRCClient;


@interface DCCController : NSWindowController

@property (nonatomic, weak) id delegate;
@property (nonatomic, weak) IRCWorld* world;
@property (nonatomic, weak) NSWindow* mainWindow;

@property (nonatomic) IBOutlet ListView* receiverTable;
@property (nonatomic) IBOutlet ListView* senderTable;
@property (nonatomic) IBOutlet ThinSplitView* splitter;
@property (nonatomic) IBOutlet NSButton* clearButton;

- (void)show:(BOOL)key;
- (void)close;
- (void)terminate;
- (void)nickChanged:(NSString*)nick toNick:(NSString*)toNick client:(IRCClient*)client;

- (void)addReceiverWithUID:(int)uid nick:(NSString*)nick host:(NSString*)host port:(int)port path:(NSString*)path fileName:(NSString*)fileName size:(long long)size;
- (void)addSenderWithUID:(int)uid nick:(NSString*)nick fileName:(NSString*)fileName autoOpen:(BOOL)autoOpen;
- (int)countReceivingItems;
- (int)countSendingItems;

- (void)clear:(id)sender;

- (void)startReceiver:(id)sender;
- (void)stopReceiver:(id)sender;
- (void)deleteReceiver:(id)sender;
- (void)openReceiver:(id)sender;
- (void)revealReceivedFileInFinder:(id)sender;

- (void)startSender:(id)sender;
- (void)stopSender:(id)sender;
- (void)deleteSender:(id)sender;

@end
