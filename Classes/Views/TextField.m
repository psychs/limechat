// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

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
