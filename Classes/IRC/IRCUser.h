// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Foundation/Foundation.h>


@interface IRCUser : NSObject

@property (nonatomic, strong) NSString* nick;
@property (nonatomic, readonly) NSString* canonicalNick;
@property (nonatomic, strong) NSString* username;
@property (nonatomic, strong) NSString* address;
@property (nonatomic) BOOL q;
@property (nonatomic) BOOL a;
@property (nonatomic) BOOL o;
@property (nonatomic) BOOL h;
@property (nonatomic) BOOL v;
@property (nonatomic) BOOL isMyself;
@property (nonatomic, readonly) char mark;
@property (nonatomic, readonly) BOOL isOp;
@property (nonatomic, readonly) int colorNumber;
@property (nonatomic, readonly) CGFloat weight;
@property (nonatomic, readonly) CGFloat incomingWeight;
@property (nonatomic, readonly) CGFloat outgoingWeight;

- (BOOL)hasMode:(char)mode;

- (void)outgoingConversation;
- (void)incomingConversation;
- (void)conversation;

- (NSComparisonResult)compare:(IRCUser*)other;

@end
