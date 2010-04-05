// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import <Cocoa/Cocoa.h>


@protocol IRCTreeItem

- (int)numberOfChildren;
- (id)childAtIndex:(int)index;
- (NSString*)label;

@end
