// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Foundation/Foundation.h>


@interface IRCUser : NSObject
{
	NSString* nick;
	NSString* canonicalNick;
	NSString* username;
	NSString* address;
	BOOL q;
	BOOL a;
	BOOL o;
	BOOL h;
	BOOL v;
	
	BOOL isMyself;
	int colorNumber;
	
	CGFloat incomingWeight;
	CGFloat outgoingWeight;
	CFAbsoluteTime lastFadedWeights;
}

@property (nonatomic, retain) NSString* nick;
@property (nonatomic, readonly) NSString* canonicalNick;
@property (nonatomic, retain) NSString* username;
@property (nonatomic, retain) NSString* address;
@property (nonatomic, assign) BOOL q;
@property (nonatomic, assign) BOOL a;
@property (nonatomic, assign) BOOL o;
@property (nonatomic, assign) BOOL h;
@property (nonatomic, assign) BOOL v;
@property (nonatomic, assign) BOOL isMyself;
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
