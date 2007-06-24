// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "LogEventSinkBase.h"

@interface LogEventSinkBase (RubyMethod)
- (void)on_doubleclick:(id)e;
- (BOOL)should_stop_doubleclick:(id)e;
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

+ (NSString*)webScriptNameForKey:(const char*)name
{
  return nil;
}

- (void)onDblClick:(id)event
{
  [self on_doubleclick:event];
}

- (BOOL)shouldStopDoubleClick:(id)event
{
  return [self should_stop_doubleclick:event];
}

- (float)getDoubleClickTime
{
  return GetDblTime();
}

- (void)print:(NSString*)s
{
  NSLog(@"%@", s);
}

@end
