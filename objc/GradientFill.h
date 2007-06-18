// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import <Cocoa/Cocoa.h>

@interface GradientFill : NSObject
{
  NSColor* beginColor;
  NSColor* endColor;
}

+ (GradientFill*)gradientWithBeginColor:(NSColor*)from endColor:(NSColor*)end;
- (void)fillRect:(NSRect)rect;

@end
