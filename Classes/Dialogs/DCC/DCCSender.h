// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Foundation/Foundation.h>
#import "DCCFileTransferCell.h"
#import "TCPServer.h"


@interface DCCSender : NSObject

@property (nonatomic, weak) id delegate;
@property (nonatomic) int uid;
@property (nonatomic) NSString* peerNick;
@property (nonatomic, readonly) int port;
@property (nonatomic, readonly) NSString* fileName;
@property (nonatomic) NSString* fullFileName;
@property (nonatomic, readonly) long long size;
@property (nonatomic, readonly) long long processedSize;
@property (nonatomic, readonly) DCCFileTransferStatus status;
@property (nonatomic, readonly) NSString* error;
@property (nonatomic, readonly) NSImage* icon;
@property (nonatomic) NSProgressIndicator* progressBar;
@property (nonatomic, readonly) double speed;

- (BOOL)open;
- (void)close;
- (void)onTimer;
- (void)setAddressError;

@end


@interface NSObject (DCCSenderDelegate)
- (void)dccSenderOnListen:(DCCSender*)sender;
- (void)dccSenderOnConnect:(DCCSender*)sender;
- (void)dccSenderOnClose:(DCCSender*)sender;
- (void)dccSenderOnError:(DCCSender*)sender;
- (void)dccSenderOnComplete:(DCCSender*)sender;
@end
