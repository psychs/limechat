// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "TextFieldWithDisabledState.h"


@implementation TextFieldWithDisabledState

- (void)setEnabled:(BOOL)value
{
	[super setEnabled:value];
	[self setTextColor:value ? [NSColor controlTextColor] : [NSColor disabledControlTextColor]];
}

@end
