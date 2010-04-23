// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the new BSD license.

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
