// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the same terms as Ruby.

#import "LogEventSinkBase.h"

@interface LogEventSinkBase (RubyMethod)
- (void)on_doubleclick:(id)e;
@end

@implementation LogEventSinkBase

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)sel
{
  if (sel == @selector(onDblClick:)
    || sel == @selector(shouldStopDoubleClick:)
    || sel == @selector(print:))
  {
    return NO;
  }
  return YES;
}

+ (NSString*)webScriptNameForSelector:(SEL)sel
{
  if (sel == @selector(onDblClick:)) {
    return @"onDblClick";
  } else if (sel == @selector(shouldStopDoubleClick:)) {
    return @"shouldStopDoubleClick";
  } else if (sel == @selector(print:)) {
    return @"print";
  }
  return nil;
}

+ (BOOL)isKeyExcludedFromWebScript:(const char*)name
{
  return YES;
}

+ (NSString *)webScriptNameForKey:(const char*)name
{
  return nil;
}

- (void)onDblClick:(id)event
{
  [self on_doubleclick:event];
}

- (BOOL)shouldStopDoubleClick:(id)event
{
  const int d = 3;
  static double last = 0.0;
  static int x = -100;
  static int y = -100;
  int cx = [[event valueForKey:@"clientX"] intValue];
  int cy = [[event valueForKey:@"clientY"] intValue];
  BOOL result = NO;
  
  double now = [NSDate timeIntervalSinceReferenceDate];
  if (x-d <= cx && cx <= x+d && y-d <= cy && cy <= y+d) {
    if (now < last + (GetDblTime() / 60.0)) result = YES;
  }
  last = now;
  x = cx;
  y = cy;
  return result;
}

- (void)print:(NSString*)s
{
  NSLog(@"%@", s);
}

@end
