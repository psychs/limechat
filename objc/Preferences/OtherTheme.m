// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "OtherTheme.h"


@implementation OtherTheme

@synthesize fileName;

- (id)init
{
	if (self = [super init]) {
	}
	return self;
}

- (void)dealloc
{
	[fileName release];
	[super dealloc];
}

- (void)setFileName:(NSString *)value
{
	if (fileName != value) {
		[fileName release];
		fileName = [value retain];
		
		[self reload];
	}
}

- (void)reload
{
	LOG(@"### loading: %@", fileName);
}

@end
