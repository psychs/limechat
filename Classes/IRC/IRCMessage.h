// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Foundation/Foundation.h>
#import "IRCPrefix.h"


@interface IRCMessage : NSObject

@property (nonatomic) time_t timestamp;
@property (nonatomic) IRCPrefix* sender;
@property (nonatomic) NSString* command;
@property (nonatomic) int numericReply;
@property (nonatomic) NSMutableArray* params;

- (id)initWithLine:(NSString*)line;

- (NSString*)paramAt:(int)index;
- (NSString*)sequence;
- (NSString*)sequence:(int)index;

@end
