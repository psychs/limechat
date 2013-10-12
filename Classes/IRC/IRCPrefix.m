// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "IRCPrefix.h"


@implementation IRCPrefix

- (id)init
{
    self = [super init];
    if (self) {
        _raw = @"";
        _nick = @"";
        _user = @"";
        _address = @"";
    }
    return self;
}

@end
