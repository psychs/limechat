// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

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

@property (nonatomic, strong) IRCISupportInfo* isupport;
@property (nonatomic) BOOL a;
@property (nonatomic) BOOL i;
@property (nonatomic) BOOL m;
@property (nonatomic) BOOL n;
@property (nonatomic) BOOL p;
@property (nonatomic) BOOL q;
@property (nonatomic) BOOL r;
@property (nonatomic) BOOL s;
@property (nonatomic) BOOL t;
@property (nonatomic) int l;
@property (nonatomic, strong) NSString* k;

- (void)clear;
- (NSArray*)update:(NSString*)str;

- (NSString*)getChangeCommand:(IRCChannelMode*)mode;

- (NSString*)string;
- (NSString*)titleString;

@end
