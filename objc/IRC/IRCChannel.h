// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import <Cocoa/Cocoa.h>
#import "IRCTreeItem.h"
#import "IRCChannelConfig.h"


@interface IRCChannel : NSObject <IRCTreeItem>
{
	IRCChannelConfig* config;
	int cid;
}

@property (nonatomic, readonly) IRCChannelConfig* config;
@property (nonatomic, assign) int cid;

- (void)setup:(IRCChannelConfig*)seed;

@end
