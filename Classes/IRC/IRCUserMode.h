// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Foundation/Foundation.h>


@interface IRCUserMode : NSObject
{
	BOOL a;
	BOOL i;
	BOOL r;
	BOOL s;
	BOOL w;
	BOOL o;
	BOOL O;
}

@property (nonatomic, assign) BOOL a;
@property (nonatomic, assign) BOOL i;
@property (nonatomic, assign) BOOL r;
@property (nonatomic, assign) BOOL s;
@property (nonatomic, assign) BOOL w;
@property (nonatomic, assign) BOOL o;
@property (nonatomic, assign) BOOL O;

- (void)clear;
- (void)update:(NSString*)str;

- (NSString*)string;

@end
