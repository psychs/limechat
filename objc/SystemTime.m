// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "SystemTime.h"
#include <sys/time.h>

@implementation SystemTime

+ (NSNumber*)gettimeofday
{
  struct timeval t = {0, 0};
  long long i = 0;
  
  gettimeofday(&t, 0);
  i = t.tv_sec;
  i *= 1000000LL;
  i += t.tv_usec;
  return [NSNumber numberWithLongLong:i];
}

@end
