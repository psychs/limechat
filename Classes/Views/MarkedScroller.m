// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "MarkedScroller.h"


@implementation MarkedScroller

@synthesize dataSource;

+ (BOOL)isCompatibleWithOverlayScrollers {
    return self == [MarkedScroller class];
}

- (void)drawKnob
{
	[super drawKnob];

	if (!dataSource) return;
	if (![dataSource respondsToSelector:@selector(markedScrollerPositions:)]) return;
	if (![dataSource respondsToSelector:@selector(markedScrollerColor:)]) return;
	
	NSScrollView* scrollView = (NSScrollView*)[self superview];
	int contentHeight = [[scrollView contentView] documentRect].size.height;
	NSArray* ary = [dataSource markedScrollerPositions:self];
	if (!ary || !ary.count) return;
	
	//
	// prepare transform
	//
	NSAffineTransform* transform = [NSAffineTransform transform];
	int width = [MarkedScroller scrollerWidth];
	CGFloat scale = [self rectForPart:NSScrollerKnobSlot].size.height / (CGFloat)contentHeight;
	int offset = [self rectForPart:NSScrollerKnobSlot].origin.y;
	[transform scaleXBy:1 yBy:scale];
	[transform translateXBy:0 yBy:offset];
	
	//
	// make lines
	//
	NSMutableArray* lines = [NSMutableArray array];
	NSPoint prev = NSMakePoint(-1, -1);
	
	for (NSNumber* e in ary) {
		int i = [e intValue];
		NSPoint pt = NSMakePoint(0, i);
		pt = [transform transformPoint:pt];
		pt.x = ceil(pt.x);
		pt.y = ceil(pt.y) + 0.5;
		if (pt.x == prev.x && pt.y == prev.y) continue;
		prev = pt;
		NSBezierPath* line = [NSBezierPath bezierPath];
		[line setLineWidth:1];
		[line moveToPoint:pt];
		[line relativeLineToPoint:NSMakePoint(width, 0)];
		[lines addObject:line];
	}
	
	//
	// draw lines
	//
	NSRectClip(NSInsetRect([self rectForPart:NSScrollerKnobSlot], 3, 4));
	NSColor* color = [dataSource markedScrollerColor:self];
	[color set];
	
	for (NSBezierPath* e in lines) {
		[e stroke];
	}
}

@end
