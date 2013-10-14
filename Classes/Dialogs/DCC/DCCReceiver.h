// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Foundation/Foundation.h>
#import "DCCFileTransferCell.h"
#import "TCPClient.h"


@interface DCCReceiver : NSObject

@property (nonatomic, weak) id delegate;
@property (nonatomic) int uid;
@property (nonatomic) NSString* peerNick;
@property (nonatomic) NSString* host;
@property (nonatomic) int port;
@property (nonatomic) long long size;
@property (nonatomic, readonly) long long processedSize;
@property (nonatomic, readonly) DCCFileTransferStatus status;
@property (nonatomic, readonly) NSString* error;
@property (nonatomic) NSString* path;
@property (nonatomic) NSString* fileName;
@property (nonatomic, readonly) NSString* downloadFileName;
@property (nonatomic, readonly) NSImage* icon;
@property (nonatomic) NSProgressIndicator* progressBar;
@property (nonatomic, readonly) double speed;

- (void)open;
- (void)close;
- (void)onTimer;

@end


@interface NSObject (DCCReceiverDelegate)
- (void)dccReceiveOnOpen:(DCCReceiver*)sender;
- (void)dccReceiveOnClose:(DCCReceiver*)sender;
- (void)dccReceiveOnError:(DCCReceiver*)sender;
- (void)dccReceiveOnComplete:(DCCReceiver*)sender;
@end
