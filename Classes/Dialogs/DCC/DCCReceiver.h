// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Foundation/Foundation.h>
#import "DCCFileTransferCell.h"
#import "TCPClient.h"


@interface DCCReceiver : NSObject
{
	id delegate;
	int uid;
	NSString* peerNick;
	NSString* host;
	int port;
	long long size;
	long long processedSize;
	DCCFileTransferStatus status;
	NSString* error;
	NSString* path;
	NSString* fileName;
	NSString* downloadFileName;
	NSImage* icon;
	NSProgressIndicator* progressBar;
	
	TCPClient* sock;
	NSFileHandle* file;
	NSMutableArray* speedRecords;
	double currentRecord;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, assign) int uid;
@property (nonatomic, retain) NSString* peerNick;
@property (nonatomic, retain) NSString* host;
@property (nonatomic, assign) int port;
@property (nonatomic, assign) long long size;
@property (nonatomic, readonly) long long processedSize;
@property (nonatomic, readonly) DCCFileTransferStatus status;
@property (nonatomic, readonly) NSString* error;
@property (nonatomic, retain) NSString* path;
@property (nonatomic, retain) NSString* fileName;
@property (nonatomic, readonly) NSString* downloadFileName;
@property (nonatomic, readonly) NSImage* icon;
@property (nonatomic, retain) NSProgressIndicator* progressBar;
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
