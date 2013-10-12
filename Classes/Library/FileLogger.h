// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Cocoa/Cocoa.h>


@class IRCClient;
@class IRCChannel;


@interface FileLogger : NSObject

@property (nonatomic, weak) IRCClient* client;
@property (nonatomic, weak) IRCChannel* channel;

- (void)open;
- (void)close;
- (void)reopenIfNeeded;

- (void)writeLine:(NSString*)s;

@end
