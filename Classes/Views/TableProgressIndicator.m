// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "TableProgressIndicator.h"


@implementation TableProgressIndicator

- (void)mouseDown:(NSEvent *)e
{
	[[self superview] mouseDown:e];
}

- (void)rightMouseDown:(NSEvent *)e
{
	[[self superview] rightMouseDown:e];
}

@end
