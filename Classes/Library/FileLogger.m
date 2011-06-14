// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "FileLogger.h"
#import "Preferences.h"
#import "IRCClient.h"
#import "IRCChannel.h"
#import "NSStringHelper.h"


@interface FileLogger (Private)
- (NSString*)buildFileName;
@end


@implementation FileLogger

@synthesize client;
@synthesize channel;

- (id)init
{
	self = [super init];
	if (self) {
	}
	return self;
}

- (void)dealloc
{
	[self close];
	[fileName release];
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
	
	if (file) {
		s = [s stringByAppendingString:@"\n"];
		
		NSData* data = [s dataUsingEncoding:NSUTF8StringEncoding];
		if (!data) {
			data = [s dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
		}
		
		if (data) {
			[file writeData:data];
		}
	}
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
	
	NSString* dir = [fileName stringByDeletingLastPathComponent];
	
	NSFileManager* fm = [NSFileManager defaultManager];
	BOOL isDir = NO;
	if (![fm fileExistsAtPath:dir isDirectory:&isDir]) {
		[fm createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:NULL];
	}
	
	if (![fm fileExistsAtPath:fileName]) {
		[fm createFileAtPath:fileName contents:[NSData data] attributes:nil];
	}
	
	[file release];
	file = [[NSFileHandle fileHandleForUpdatingAtPath:fileName] retain];
	if (file) {
		[file seekToEndOfFile];
	}
}

- (NSString*)buildFileName
{
	NSString* base = [Preferences transcriptFolder];
	base = [base stringByExpandingTildeInPath];
	
	static NSDateFormatter* format = nil;
	if (!format) {
		format = [NSDateFormatter new];
		[format setDateFormat:@"YYYY-MM-dd"];
	}
	NSString* date = [format stringFromDate:[NSDate date]];
	NSString* name = [[client name] safeFileName];
	NSString* pre = @"";
	NSString* c = @"";
	
	if (!channel) {
		c = @"Console";
	}
	else if ([channel isTalk]) {
		c = @"Talk";
		pre = [[[channel name] safeFileName] stringByAppendingString:@"_"];
	}
	else {
		c = [[channel name] safeFileName];
	}
	
	return [base stringByAppendingFormat:@"/%@/%@%@_%@.txt", c, pre, date, name];
}

@end
