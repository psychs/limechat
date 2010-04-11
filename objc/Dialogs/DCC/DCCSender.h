// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import <Foundation/Foundation.h>
#import "DCCFileTransferCell.h"
#import "TCPServer.h"


@interface DCCSender : NSObject
{
	id delegate;
	int uid;
	NSString* peerNick;
	int port;
	NSString* fileName;
	NSString* fullFileName;
	long long size;
	long long processedSize;
	DCCFileTransferStatus status;
	NSString* error;
	NSImage* icon;
	NSProgressIndicator* progressBar;

	TCPServer* sock;
	TCPClient* client;
	NSFileHandle* file;
	NSMutableArray* speedRecords;
	double currentRecord;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, assign) int uid;
@property (nonatomic, retain) NSString* peerNick;
@property (nonatomic, readonly) int port;
@property (nonatomic, readonly) NSString* fileName;
@property (nonatomic, retain) NSString* fullFileName;
@property (nonatomic, readonly) long long size;
@property (nonatomic, readonly) long long processedSize;
@property (nonatomic, readonly) DCCFileTransferStatus status;
@property (nonatomic, readonly) NSString* error;
@property (nonatomic, readonly) NSImage* icon;
@property (nonatomic, retain) NSProgressIndicator* progressBar;
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
