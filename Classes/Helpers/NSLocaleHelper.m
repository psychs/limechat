// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

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
