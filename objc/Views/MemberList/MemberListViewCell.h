// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

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
