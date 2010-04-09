// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

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
