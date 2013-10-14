// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Foundation/Foundation.h>


typedef enum {
    DCC_INIT,
    DCC_ERROR,
    DCC_STOP,
    DCC_CONNECTING,
    DCC_LISTENING,
    DCC_RECEIVING,
    DCC_SENDING,
    DCC_COMPLETE,
} DCCFileTransferStatus;


@interface DCCFileTransferCell : NSCell

@property (nonatomic) NSString* peerNick;
@property (nonatomic) long long processedSize;
@property (nonatomic) long long size;
@property (nonatomic) long long speed;
@property (nonatomic) long long timeRemaining;
@property (nonatomic) DCCFileTransferStatus status;
@property (nonatomic) NSString* error;
@property (nonatomic) NSProgressIndicator* progressBar;
@property (nonatomic) NSImage* icon;
@property (nonatomic) BOOL sendingItem;

@end
