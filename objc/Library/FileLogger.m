// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "FileLogger.h"
#import "Preferences.h"


@interface FileLogger (Private)
- (void)open;
- (NSString*)buildFileName;
@end


@implementation FileLogger

@synthesize client;
@synthesize channel;

- (id)init
{
	if (self = [super init]) {
	}
	return self;
}

- (void)dealloc
{
	[fileName release];
	[file release];
	[super dealloc];
}

- (void)close
{
	if (file) {
		[file closeFile];
		[file release];
		file = nil;
	}
}

- (void)writeLine:(NSString*)s
{
	[self open];
}

- (void)reopenIfNeeded
{
	if (!fileName || ![fileName isEqualToString:[self buildFileName]]) {
		[self open];
	}
}

- (void)open
{
	[self close];
	
	[fileName release];
	fileName = [[self buildFileName] retain];
	
	LOG(@"### filename: %@", fileName);
}

- (NSString*)buildFileName
{
	NSString* base = [NewPreferences stringForKey:@"Preferences.General.transcript_folder"];
	base = [base stringByExpandingTildeInPath];
	
	static NSDateFormatter* format = nil;
	if (!format) {
		format = [NSDateFormatter new];
		[format setDateFormat:@"YYYY-MM-dd"];
	}
	NSString* date = [format stringFromDate:[NSDate date]];
	NSString* name = [client name];
	NSString* pre = @"";
	NSString* c = @"";
	
	if (!channel) {
		c = @"Console";
	}
	else if ([channel isTalk]) {
		c = @"Talk";
		pre = @"_";
	}
	else {
		c = [channel name];
	}
	
	return [base stringByAppendingFormat:@"/%@%@_%@.txt", pre, date, name];
}




































@end
