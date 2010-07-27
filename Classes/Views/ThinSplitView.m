// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "ThinSplitView.h"


@interface ThinSplitView (Private)
- (void)updatePosition;
@end


@implementation ThinSplitView

@synthesize fixedViewIndex;
@synthesize position;
@synthesize inverted;
@synthesize hidden;


- (void)setUp
{
	myDividerThickness = 1;
}

- (id)initWithFrame:(NSRect)rect
{
	if (self = [super initWithFrame:rect]) {
		[self setUp];
	}
	return self;
}

- (id)initWithCoder:(NSCoder*)coder
{
	if (self = [super initWithCoder:coder]) {
		[self setUp];
	}
	return self;
}

- (void)awakeFromNib
{
	myDividerThickness = [self isVertical] ? 1 : 5;
	[self updatePosition];
}

- (void)dealloc
{
	[super dealloc];
}

- (CGFloat)dividerThickness
{
	return myDividerThickness;
}

- (void)setFixedViewIndex:(int)value
{
	if (fixedViewIndex != value) {
		fixedViewIndex = value;
		if (inverted) {
			fixedViewIndex = fixedViewIndex ? 0 : 1;
		}
	}
}

- (void)setPosition:(int)value
{
	position = value;
	[self adjustSubviews];
}

- (void)setDividerThickness:(int)value
{
	myDividerThickness = value;
	[self setDividerThickness:myDividerThickness];
	[self adjustSubviews];
}

- (void)setInverted:(BOOL)value
{
	if (inverted == value) return;
	inverted = value;
	
	NSView* a = [[[[self subviews] objectAtIndex:0] retain] autorelease];
	NSView* b = [[[[self subviews] objectAtIndex:1] retain] autorelease];
	
	[a removeFromSuperviewWithoutNeedingDisplay];
	[b removeFromSuperviewWithoutNeedingDisplay];
	[self addSubview:b];
	[self addSubview:a];
	
	fixedViewIndex = fixedViewIndex ? 0 : 1;
	
	[self adjustSubviews];
}

- (void)setVertical:(BOOL)value
{
	[super setVertical:value];
	
	myDividerThickness = value ? 1 : 5;
	[self adjustSubviews];
}

- (void)setHidden:(BOOL)value
{
	if (hidden == value) return;
	hidden = value;
	[self adjustSubviews];
}

- (void)drawDividerInRect:(NSRect)rect
{
	if (hidden) return;
	
	if ([self isVertical]) {
		[[NSColor colorWithCalibratedWhite:0.65 alpha:1] set];
		NSRectFill(rect);
	}
	else {
		[[NSColor colorWithCalibratedWhite:0.65 alpha:1] set];
		NSPoint left, right;
		
		left = rect.origin;
		right = left;
		right.x += rect.size.width;
		[NSBezierPath strokeLineFromPoint:left toPoint:right];
		
		left = rect.origin;
		left.y += rect.size.height;
		right = left;
		right.x += rect.size.width;
		[NSBezierPath strokeLineFromPoint:left toPoint:right];
	}
}

- (void)mouseDown:(NSEvent*)e
{
	[super mouseDown:e];
	[self updatePosition];
}

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize
{
	[self adjustSubviews];
}

- (void)adjustSubviews
{
	if ([[self subviews] count] != 2) {
		[super adjustSubviews];
		return;
	}
	
	NSSize size = self.frame.size;
	int width = size.width;
	int height = size.height;
	int w = myDividerThickness;
	
	NSView* fixedView = [[self subviews] objectAtIndex:fixedViewIndex];
	NSView* flyingView = [[self subviews] objectAtIndex:fixedViewIndex ? 0 : 1];
	NSRect fixedFrame = fixedView.frame;
	NSRect flyingFrame = flyingView.frame;

	if (hidden) {
		if ([self isVertical]) {
			fixedFrame = NSMakeRect(0, 0, 0, height);
			flyingFrame.origin = NSZeroPoint;
			flyingFrame.size = size;
		}
		else {
			fixedFrame = NSMakeRect(0, 0, width, 0);
			flyingFrame.origin = NSZeroPoint;
			flyingFrame.size = size;
		}
	}
	else {
		if ([self isVertical]) {
			flyingFrame.size.width = width - w - position;
			flyingFrame.size.height = height;
			flyingFrame.origin.x = fixedViewIndex ? 0 : position + w;
			flyingFrame.origin.y = 0;
			if (flyingFrame.size.width < 0) flyingFrame.size.width = 0;
			
			fixedFrame.size.width = position;
			fixedFrame.size.height = height;
			fixedFrame.origin.x = fixedViewIndex ? flyingFrame.size.width + w : 0;
			fixedFrame.origin.y = 0;
			if (fixedFrame.size.width > width - w) fixedFrame.size.width = width - w;
		}
		else {
			flyingFrame.size.width = width;
			flyingFrame.size.height = height - w - position;
			flyingFrame.origin.x = 0;
			flyingFrame.origin.y = fixedViewIndex ? 0 : position + w;
			if (flyingFrame.size.height < 0) flyingFrame.size.height = 0;
			
			fixedFrame.size.width = width;
			fixedFrame.size.height = position;
			fixedFrame.origin.x = 0;
			fixedFrame.origin.y = fixedViewIndex ? flyingFrame.size.height + w : 0;
			if (fixedFrame.size.height > height - w) fixedFrame.size.height = height - w;
		}
	}
	
	[fixedView setFrame:fixedFrame];
	[flyingView setFrame:flyingFrame];
	[self setNeedsDisplay:YES];
	[[self window] invalidateCursorRectsForView:self];
}

- (void)updatePosition
{
	NSView* view =  [[self subviews] objectAtIndex:fixedViewIndex];
	NSSize size = view.frame.size;
	position = [self isVertical] ? size.width : size.height;
}

@end
