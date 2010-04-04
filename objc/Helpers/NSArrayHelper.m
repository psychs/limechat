#import "NSArrayHelper.h"


@implementation NSArray (NSArrayHelper)

- (NSString*)safeStringAtIndex:(int)n
{
	if (0 <= n && n < self.count) {
		NSString* s = [self objectAtIndex:n];
		if ([s isKindOfClass:[NSString class]]) {
			return s;
		}
	}
	return @"";
}

@end
