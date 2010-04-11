// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import <Foundation/Foundation.h>
#import "DCCFileTransferCell.h"


@interface DCCSender : NSObject
{
	id delegate;
	int uid;
	NSString* peerNick;
	int port;
	NSString* fileName;
	long long size;
	long long processedSize;
	DCCFileTransferStatus status;
	NSString* error;
	NSImage* icon;
	NSProgressIndicator* progressBar;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, assign) int uid;
@property (nonatomic, retain) NSString* peerNick;
@property (nonatomic, assign) int port;
@property (nonatomic, retain) NSString* fileName;
@property (nonatomic, assign) long long size;
@property (nonatomic, assign) long long processedSize;
@property (nonatomic, assign) DCCFileTransferStatus status;
@property (nonatomic, retain) NSString* error;
@property (nonatomic, retain) NSImage* icon;
@property (nonatomic, retain) NSProgressIndicator* progressBar;

- (void)open;
- (void)close;
- (void)onTimer;

@end


@interface NSObject (DCCSenderDelegate)
- (void)dccSenderOnError:(DCCSender*)sender;
- (void)dccSenderOnComplete:(DCCSender*)sender;
- (void)dccSenderOnListen:(DCCSender*)sender;
- (void)dccSenderOnConnect:(DCCSender*)sender;
- (void)dccSenderOnClose:(DCCSender*)sender;
@end
