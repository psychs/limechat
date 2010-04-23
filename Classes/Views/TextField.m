// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the new BSD license.

#import "TextField.h"


@implementation TextField

- (void)focus
{
	[self.window makeFirstResponder:self];
	NSText* e = [self currentEditor];
	[e setSelectedRange:NSMakeRange([[self stringValue] length], 0)];
	[e scrollRangeToVisible:[e selectedRange]];
}

@end
