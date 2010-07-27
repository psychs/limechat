// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Foundation/Foundation.h>


@interface IRCPrefix : NSObject
{
	NSString* raw;
	NSString* nick;
	NSString* user;
	NSString* address;
	BOOL isServer;
}

@property (nonatomic, retain) NSString* raw;
@property (nonatomic, retain) NSString* nick;
@property (nonatomic, retain) NSString* user;
@property (nonatomic, retain) NSString* address;
@property (nonatomic, assign) BOOL isServer;

@end
