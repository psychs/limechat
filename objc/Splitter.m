// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "Splitter.h"

@interface Splitter (Private)
- (void)setup;
- (void)updatePosition;
@end

@implementation Splitter (Private)

- (void)setup
{
//  [self setDelegate:self];
}

- (void)updatePosition
{
  NSRect frame = [[[self subviews] objectAtIndex:fixedViewIndex] frame];
  position = [self isVertical] ? NSWidth(frame) : NSHeight(frame);
}

@end


@implementation Splitter

- (id)initWithFrame:(NSRect)frame
{
  self = [super initWithFrame:frame];
  [self setup];
  return self;
}

- (id)initWithCoder:(NSCoder*)coder
{
  self = [super initWithCoder:coder];
  [self setup];
  return self;
}

- (void)awakeFromNib
{
  myDividerThickness = [self isVertical] ? 1.0 : 5.0;
  [self updatePosition];
}

- (void)setFixedViewIndex:(int)index
{
  fixedViewIndex = index != 0;
  if (inverted) fixedViewIndex = fixedViewIndex ? 0 : 1;
  [self updatePosition];
}

- (int)fixedViewIndex
{
  int index = fixedViewIndex;
  if (inverted) index = index ? 0 : 1;
  return index;
}

- (void)setPosition:(float)pos
{
  position = pos;
  [self adjustSubviews];
}

- (float)position
{
  return position;
}

- (void)setDividerThickness:(float)value
{
  myDividerThickness = value;
  [self adjustSubviews];
}

- (float)dividerThickness
{
  return myDividerThickness;
}

- (void)setInverted:(BOOL)value
{
  if (inverted == value) return;
  inverted = value;
  
  NSView* v = [[[self subviews] objectAtIndex:0] retain];
  NSView* w = [[[self subviews] objectAtIndex:1] retain];
  [v removeFromSuperviewWithoutNeedingDisplay];
  [w removeFromSuperviewWithoutNeedingDisplay];
  [self addSubview:w];
  [self addSubview:v];
  [v release];
  [w release];
  fixedViewIndex = fixedViewIndex ? 0 : 1;
  
  [self adjustSubviews];
}

- (BOOL)inverted
{
  return inverted;
}

- (void)setVertical:(BOOL)value
{
  [super setVertical:value];
  [self adjustSubviews];
}

- (void)drawDividerInRect:(NSRect)rect
{
  if ([self isVertical]) {
    [[NSColor colorWithCalibratedWhite:0.65 alpha:1.] set];
    NSRectFill(rect);
  } else {
    [[NSColor colorWithCalibratedWhite:0.65 alpha:1.] set];
    NSPoint start, end;
    start.x = rect.origin.x;
    start.y = rect.origin.y;
    end.x = start.x + NSWidth(rect);
    end.y = start.y;
    [NSBezierPath strokeLineFromPoint:start toPoint:end];
    start.x = rect.origin.x;
    start.y = rect.origin.y + NSHeight(rect);
    end.x = start.x + NSWidth(rect);
    end.y = start.y;
    [NSBezierPath strokeLineFromPoint:start toPoint:end];
  }
}

- (void)mouseDown:(NSEvent*)event
{
  [super mouseDown:event];
  [self updatePosition];
}

- (float)splitView:(NSSplitView*)sender constrainMinCoordinate:(float)proposedMin ofSubviewAt:(int)offset
{
  if ([self isVertical]) {
    if (offset == 0) {
      return 30.0;
    }
  }
  return proposedMin;
}

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize
{
  [self adjustSubviews];
}

- (void)adjustSubviews
{
  if (fixedViewIndex == -1 || [[self subviews] count] != 2) {
    [super adjustSubviews];
    return;
  }
  
  float dividerThickness = [self dividerThickness];
  NSRect frame = [self frame];
  NSView* fixedView = [[self subviews] objectAtIndex:fixedViewIndex];
  NSView* flyingView = [[self subviews] objectAtIndex:fixedViewIndex == 0 ? 1 : 0];
  NSRect fixedFrame = [fixedView frame];
  NSRect flyingFrame = [flyingView frame];
  
  if ([self isVertical]) {
    flyingFrame.size.width = NSWidth(frame) - dividerThickness - position;
    flyingFrame.size.height = NSHeight(frame);
    flyingFrame.origin.x = fixedViewIndex == 0 ? position + dividerThickness : 0.0;
    flyingFrame.origin.y = 0.0;
    if (flyingFrame.size.width < 0.0) {
      flyingFrame.size.width = 0.0;
    }
    fixedFrame.size.width = position;
    fixedFrame.size.height = NSHeight(frame);
    fixedFrame.origin.x = fixedViewIndex == 0 ? 0.0 : NSWidth(flyingFrame) + dividerThickness;
    fixedFrame.origin.y = 0.0;
    if (fixedFrame.size.width > NSWidth(frame) - dividerThickness) {
      fixedFrame.size.width = NSWidth(frame) - dividerThickness;
    }
  } else {
    flyingFrame.size.width = NSWidth(frame);
    flyingFrame.size.height = NSHeight(frame) - dividerThickness - position;
    flyingFrame.origin.x = 0.0;
    flyingFrame.origin.y = fixedViewIndex == 0 ? position + dividerThickness : 0.0;
    if (flyingFrame.size.height < 0.0) {
      flyingFrame.size.height = 0.0;
    }
    fixedFrame.size.width = NSWidth(frame);
    fixedFrame.size.height = position;
    fixedFrame.origin.x = 0.0;
    fixedFrame.origin.y = fixedViewIndex == 0 ? 0.0 : NSHeight(flyingFrame) + dividerThickness;
    if (fixedFrame.size.height > NSHeight(frame) - dividerThickness) {
      fixedFrame.size.height = NSHeight(frame) - dividerThickness;
    }
  }
  
  [flyingView setFrame:flyingFrame];
  [fixedView setFrame:fixedFrame];
  [self setNeedsDisplay:YES];
  [[self window] invalidateCursorRectsForView:self];
}

@end
