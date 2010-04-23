// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "CustomJSFile.h"


@interface CustomJSFile (Private)
@end


@implementation CustomJSFile

@synthesize fileName;
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
