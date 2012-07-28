// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Foundation/Foundation.h>


@interface IRCUserMode : NSObject

@property (nonatomic) BOOL a;
@property (nonatomic) BOOL i;
@property (nonatomic) BOOL r;
@property (nonatomic) BOOL s;
@property (nonatomic) BOOL w;
@property (nonatomic) BOOL o;
@property (nonatomic) BOOL O;

- (void)clear;
- (void)update:(NSString*)str;

- (NSString*)string;

@end
