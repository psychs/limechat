// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

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
