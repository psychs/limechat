// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

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
	
	int colorNumber;
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
@property (nonatomic, readonly) char mark;
@property (nonatomic, readonly) BOOL isOp;
@property (nonatomic, readonly) int colorNumber;

@end
