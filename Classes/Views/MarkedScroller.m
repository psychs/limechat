// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "MarkedScroller.h"


@implementation MarkedScroller

@synthesize dataSource;
@synthesize markData;

const static int INSET = 3;

+ (BOOL)isCompatibleWithOverlayScrollers
{
	return self == [MarkedScroller class];
}

- (void)updateScroller
{
	self.markData = [dataSource markedScrollerPositions:self];
}

- (void)drawContentInMarkedScroller
{
	if (!dataSource) return;
	if (![dataSource respondsToSelector:@selector(markedScrollerPositions:)]) return;
	if (![dataSource respondsToSelector:@selector(markedScrollerColor:)]) return;
	
	NSScrollView* scrollView = (NSScrollView*)[self superview];
	int contentHeight = [[scrollView contentView] documentRect].size.height;
	if (!markData || !markData.count) return;
	
	//
	// prepare transform
	//
	NSAffineTransform* transform = [NSAffineTransform transform];
	int width = [self rectForPart:NSScrollerKnobSlot].size.width - INSET * 2;
	CGFloat scale = [self rectForPart:NSScrollerKnobSlot].size.height / (CGFloat)contentHeight;
	int offset = [self rectForPart:NSScrollerKnobSlot].origin.y;
	int indent = [self rectForPart:NSScrollerKnobSlot].origin.x + INSET;
	[transform scaleXBy:1 yBy:scale];
	[transform translateXBy:0 yBy:offset];
	
	//
	// make lines
	//
	NSMutableArray* lines = [NSMutableArray array];
	NSPoint prev = NSMakePoint(-1, -1);
	
	for (NSNumber* e in markData) {
		int i = [e intValue];
		NSPoint pt = NSMakePoint(indent, i);
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
	NSColor* color = [dataSource markedScrollerColor:self];
	[color set];
	
	for (NSBezierPath* e in lines) {
		[e stroke];
	}
}

- (void)drawKnob
{
	[self drawContentInMarkedScroller];
	[super drawKnob];
}

@end
