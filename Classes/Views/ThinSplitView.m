// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "ThinSplitView.h"


@implementation ThinSplitView
{
    int _myDividerThickness;
    BOOL _hidden;
}

- (void)setUp
{
    _myDividerThickness = 1;
}

- (id)initWithFrame:(NSRect)rect
{
    self = [super initWithFrame:rect];
    if (self) {
        [self setUp];
    }
    return self;
}

- (id)initWithCoder:(NSCoder*)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setUp];
    }
    return self;
}

- (void)awakeFromNib
{
    _myDividerThickness = [self isVertical] ? 1 : 5;
    [self updatePosition];
}

- (CGFloat)dividerThickness
{
    return _myDividerThickness;
}

- (void)setFixedViewIndex:(int)value
{
    if (_fixedViewIndex != value) {
        _fixedViewIndex = value;
        if (_inverted) {
            _fixedViewIndex = _fixedViewIndex ? 0 : 1;
        }
    }
}

- (void)setPosition:(int)value
{
    _position = value;
    [self adjustSubviews];
}

- (void)setDividerThickness:(int)value
{
    _myDividerThickness = value;
    [self setDividerThickness:_myDividerThickness];
    [self adjustSubviews];
}

- (void)setInverted:(BOOL)value
{
    if (_inverted == value) return;
    _inverted = value;

    NSView* a = [[self subviews] objectAtIndex:0];
    NSView* b = [[self subviews] objectAtIndex:1];

    [a removeFromSuperviewWithoutNeedingDisplay];
    [b removeFromSuperviewWithoutNeedingDisplay];
    [self addSubview:b];
    [self addSubview:a];

    _fixedViewIndex = _fixedViewIndex ? 0 : 1;

    [self adjustSubviews];
}

- (void)setVertical:(BOOL)value
{
    [super setVertical:value];

    _myDividerThickness = value ? 1 : 5;
    [self adjustSubviews];
}

- (void)setHidden:(BOOL)value
{
    if (_hidden == value) return;
    _hidden = value;
    [self adjustSubviews];
}

- (void)drawDividerInRect:(NSRect)rect
{
    if (_hidden) return;

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
    int w = _myDividerThickness;

    NSView* fixedView = [[self subviews] objectAtIndex:_fixedViewIndex];
    NSView* flyingView = [[self subviews] objectAtIndex:_fixedViewIndex ? 0 : 1];
    NSRect fixedFrame = fixedView.frame;
    NSRect flyingFrame = flyingView.frame;

    if (_hidden) {
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
            flyingFrame.size.width = width - w - _position;
            flyingFrame.size.height = height;
            flyingFrame.origin.x = _fixedViewIndex ? 0 : _position + w;
            flyingFrame.origin.y = 0;
            if (flyingFrame.size.width < 0) flyingFrame.size.width = 0;

            fixedFrame.size.width = _position;
            fixedFrame.size.height = height;
            fixedFrame.origin.x = _fixedViewIndex ? flyingFrame.size.width + w : 0;
            fixedFrame.origin.y = 0;
            if (fixedFrame.size.width > width - w) fixedFrame.size.width = width - w;
        }
        else {
            flyingFrame.size.width = width;
            flyingFrame.size.height = height - w - _position;
            flyingFrame.origin.x = 0;
            flyingFrame.origin.y = _fixedViewIndex ? 0 : _position + w;
            if (flyingFrame.size.height < 0) flyingFrame.size.height = 0;

            fixedFrame.size.width = width;
            fixedFrame.size.height = _position;
            fixedFrame.origin.x = 0;
            fixedFrame.origin.y = _fixedViewIndex ? flyingFrame.size.height + w : 0;
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
    NSView* view =  [[self subviews] objectAtIndex:_fixedViewIndex];
    NSSize size = view.frame.size;
    _position = [self isVertical] ? size.width : size.height;
}

@end
