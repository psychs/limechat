// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

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
