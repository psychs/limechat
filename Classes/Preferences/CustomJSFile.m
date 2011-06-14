// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "CustomJSFile.h"


@interface CustomJSFile (Private)
@end


@implementation CustomJSFile

@synthesize fileName;
@synthesize content;

- (id)init
{
	self = [super init];
	if (self) {
	}
	return self;
}

- (void)dealloc
{
	[fileName release];
	[content release];
	[super dealloc];
}

- (void)setFileName:(NSString *)value
{
	if (fileName != value) {
		[fileName release];
		fileName = [value retain];
	}
	
	[self reload];
}

- (void)reload
{
	[content release];
	
	NSData* data = [NSData dataWithContentsOfFile:fileName];
	content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

@end
