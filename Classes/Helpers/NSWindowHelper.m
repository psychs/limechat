// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "NSWindowHelper.h"
#import "NSRectHelper.h"


@implementation NSWindow (NSWindowHelper)

- (void)centerOfWindow:(NSWindow*)window
{
	NSPoint p = NSRectCenter(window.frame);
	NSRect frame = self.frame;
	NSSize size = frame.size;
	p.x -= size.width/2;
	p.y -= size.height/2;
	
	NSScreen* screen = window.screen;
	if (screen) {
		NSRect screenFrame = [screen visibleFrame];
		NSRect r = frame;
		r.origin = p;
		if (!NSContainsRect(screenFrame, r)) {
			r = NSRectAdjustInRect(r, screenFrame);
			p = r.origin;
		}
	}
	
	[self setFrameOrigin:p];
}

@end
