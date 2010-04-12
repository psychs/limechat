// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "NSArrayHelper.h"


@implementation NSArray (NSArrayHelper)

- (id)safeObjectAtIndex:(int)n
{
	if (0 <= n && n < self.count) {
		return [self objectAtIndex:n];
	}
	return nil;
}

@end
