// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the new BSD license.

#import "TextFieldWithDisabledState.h"


@implementation TextFieldWithDisabledState

- (void)setEnabled:(BOOL)value
{
	[super setEnabled:value];
	[self setTextColor:value ? [NSColor controlTextColor] : [NSColor disabledControlTextColor]];
}

@end
