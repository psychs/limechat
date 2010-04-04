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
