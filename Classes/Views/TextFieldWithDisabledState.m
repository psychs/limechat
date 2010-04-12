// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "TextFieldWithDisabledState.h"


@implementation TextFieldWithDisabledState

- (void)setEnabled:(BOOL)value
{
	[super setEnabled:value];
	[self setTextColor:value ? [NSColor controlTextColor] : [NSColor disabledControlTextColor]];
}

@end
