// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "NSPasteboardHelper.h"


@implementation NSPasteboard (NSPasteboardHelper)

- (BOOL)hasStringContent
{
	return [self availableTypeFromArray:[NSArray arrayWithObject:NSStringPboardType]] != nil;
}

- (NSString*)stringContent
{
	return [self stringForType:NSStringPboardType];
}

- (void)setStringContent:(NSString*)s
{
	[self declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
	[self setString:s forType:NSStringPboardType];
}

@end
