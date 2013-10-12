// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Foundation/Foundation.h>


@interface IRCPrefix : NSObject

@property (nonatomic, strong) NSString* raw;
@property (nonatomic, strong) NSString* nick;
@property (nonatomic, strong) NSString* user;
@property (nonatomic, strong) NSString* address;
@property (nonatomic) BOOL isServer;

@end
