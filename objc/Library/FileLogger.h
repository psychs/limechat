// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import <Cocoa/Cocoa.h>


@class IRCClient;
@class IRCChannel;


@interface FileLogger : NSObject
{
	IRCClient* client;
	IRCChannel* channel;
	
	NSString* fileName;
	NSFileHandle* file;
}

@property (nonatomic, assign) IRCClient* client;
@property (nonatomic, assign) IRCChannel* channel;

- (void)open;
- (void)close;
- (void)reopenIfNeeded;

- (void)writeLine:(NSString*)s;

@end
