// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "Preferences.h"


@implementation NewPreferences

+ (NSDictionary*)loadWorld
{
	return [self dictionaryForKey:@"world"];
}

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

+ (NSDictionary*)dictionaryForKey:(NSString*)key
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	NSDictionary* s = [ud objectForKey:key];
	if ([s isKindOfClass:[NSDictionary class]]) {
		return s;
	}
	return nil;
}

@end
