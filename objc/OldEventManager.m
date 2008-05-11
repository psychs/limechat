// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "OldEventManager.h"

@implementation OldEventManager

+ (NSNumber*)getDoubleClickTime
{
  return [NSNumber numberWithFloat:GetDblTime()];
}

@end
