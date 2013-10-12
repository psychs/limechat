// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "IRCTreeItem.h"


@implementation IRCTreeItem

- (IRCClient*)client
{
    return nil;
}

- (BOOL)isClient
{
    return NO;
}

- (void)resetState
{
    _isKeyword = _isUnread = _isNewTalk = NO;
}

- (int)numberOfChildren
{
    return 0;
}

- (IRCTreeItem*)childAtIndex:(int)index
{
    return nil;
}

- (NSString*)label
{
    return @"";
}

- (NSString*)name
{
    return @"";
}

@end
