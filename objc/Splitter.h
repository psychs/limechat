// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

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
