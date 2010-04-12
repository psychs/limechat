// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import <Foundation/Foundation.h>
#import "IRCPrefix.h"


@interface IRCMessage : NSObject
{
	IRCPrefix* sender;
	NSString* command;
	int numericReply;
	NSMutableArray* params;
}

@property (nonatomic, retain) IRCPrefix* sender;
@property (nonatomic, retain) NSString* command;
@property (nonatomic, assign) int numericReply;
@property (nonatomic, retain) NSMutableArray* params;

- (id)initWithLine:(NSString*)line;

- (NSString*)paramAt:(int)index;
- (NSString*)sequence;
- (NSString*)sequence:(int)index;

@end
