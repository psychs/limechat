// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import <Foundation/Foundation.h>
#import "IRCISupportInfo.h"


@interface IRCChannelMode : NSObject <NSMutableCopying>
{
	IRCISupportInfo* isupport;
	BOOL a;
	BOOL i;
	BOOL m;
	BOOL n;
	BOOL p;
	BOOL q;
	BOOL r;
	BOOL s;
	BOOL t;
	int l;
	NSString* k;
}

@property (nonatomic, retain) IRCISupportInfo* isupport;
@property (nonatomic, assign) BOOL a;
@property (nonatomic, assign) BOOL i;
@property (nonatomic, assign) BOOL m;
@property (nonatomic, assign) BOOL n;
@property (nonatomic, assign) BOOL p;
@property (nonatomic, assign) BOOL q;
@property (nonatomic, assign) BOOL r;
@property (nonatomic, assign) BOOL s;
@property (nonatomic, assign) BOOL t;
@property (nonatomic, assign) int l;
@property (nonatomic, retain) NSString* k;

- (void)clear;
- (NSArray*)update:(NSString*)str;

- (NSString*)getChangeCommand:(IRCChannelMode*)mode;

- (NSString*)string;
- (NSString*)titleString;

@end
