// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Cocoa/Cocoa.h>
#import "OtherTheme.h"
#import "IRCUser.h"


@interface MemberListViewCell : NSCell
{
	IRCUser* member;
}

@property (nonatomic, retain) IRCUser* member;

- (void)setup:(OtherTheme*)theme;
- (void)themeChanged;

@end
