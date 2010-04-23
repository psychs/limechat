// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the new BSD license.

#import "NSLocaleHelper.h"


@implementation NSLocale (NSLocaleHelper)

+ (BOOL)prefersJapaneseLanguage
{
	NSArray* langs = [self preferredLanguages];
	if (langs.count) {
		NSString* primary = [langs objectAtIndex:0];
		if ([primary isEqualToString:@"ja"]) {
			return YES;
		}
	}
	return NO;
}

@end
