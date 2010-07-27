// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "SingleLineFormatter.h"


@implementation SingleLineFormatter

- (NSString*)stringForObjectValue:(id)str
{
	str = [str stringByReplacingOccurrencesOfString:@"\r" withString:@" "];
	return [str stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
}

- (BOOL)getObjectValue:(id*)obj forString:(NSString*)str errorDescription:(NSString**)err
{
	str = [str stringByReplacingOccurrencesOfString:@"\r" withString:@" "];
	str = [str stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
	*obj = str;
	return YES;
}

- (BOOL)isPartialStringValid:(NSString *)str newEditingString:(NSString **)newString errorDescription:(NSString **)err
{
	NSRange r = [str rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]];
	if (r.location == NSNotFound) return YES;
	
	str = [str stringByReplacingOccurrencesOfString:@"\r" withString:@" "];
	str = [str stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
	*newString = str;
	return NO;
}

@end
