// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the same terms as Ruby.

#import <Cocoa/Cocoa.h>

@interface Splitter : NSSplitView
{
	int fixedViewIndex;
	float position;
	float myDividerThickness;
	BOOL inverted;
}

- (void)setFixedViewIndex:(int)index;
- (int)fixedViewIndex;
- (void)setPosition:(float)pos;
- (float)position;
- (void)setDividerThickness:(float)value;
- (float)dividerThickness;
- (void)setInverted:(BOOL)value;
- (BOOL)inverted;
- (void)setVertical:(BOOL)value;

@end
