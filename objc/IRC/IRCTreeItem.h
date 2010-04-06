// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import <Cocoa/Cocoa.h>
#import "LogController.h"


@class IRCClient;


@protocol IRCTreeItem

- (BOOL)isClient;
- (IRCClient*)client;
- (LogController*)log;

- (void)resetState;

- (int)numberOfChildren;
- (id)childAtIndex:(int)index;
- (NSString*)label;

@end
