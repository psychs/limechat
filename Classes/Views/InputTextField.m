// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the new BSD license.

#import "InputTextField.h"


@implementation InputTextField

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
	[[self backgroundColor] set];
	NSFrameRectWithWidth([self bounds], 3);
}

@end
