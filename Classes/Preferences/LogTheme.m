// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "LogTheme.h"


@implementation LogTheme

@synthesize fileName;
@synthesize baseUrl;
@synthesize content;

- (id)init
{
	if (self = [super init]) {
	}
	return self;
}

- (void)dealloc
{
	[fileName release];
	[baseUrl release];
	[content release];
	[super dealloc];
}

- (void)setFileName:(NSString *)value
{
	if (fileName != value) {
		[fileName release];
		fileName = [value retain];

		[baseUrl release];
		baseUrl = nil;

		if (fileName) {
			baseUrl = [[NSURL fileURLWithPath:[fileName stringByDeletingLastPathComponent]] retain];
		}
	}
	
	[self reload];
}

- (void)reload
{
	[content release];
	content = nil;
	
	if (fileName) {
		content = [[NSString stringWithContentsOfFile:fileName encoding:NSUTF8StringEncoding error:NULL] retain];
	}
}

@end
