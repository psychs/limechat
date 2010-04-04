#import "Preferences.h"


@implementation NewPreferences

+ (BOOL)boolForKey:(NSString*)key
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud boolForKey:key];
}

+ (NSString*)stringForKey:(NSString*)key
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	NSString* s = [ud objectForKey:key];
	if ([s isKindOfClass:[NSString class]]) {
		return s;
	}
	return nil;
}

@end
