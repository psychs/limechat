// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "InputTextField.h"


@implementation InputTextField

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
	[[self backgroundColor] set];
	NSFrameRectWithWidth([self bounds], 3);
}

@end
