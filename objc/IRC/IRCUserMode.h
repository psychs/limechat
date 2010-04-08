// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

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
