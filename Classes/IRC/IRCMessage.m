// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "IRCMessage.h"
#import "NSStringHelper.h"


@interface IRCMessage (Private)
- (void)parseLine:(NSString*)line;
@end


@implementation IRCMessage

@synthesize sender;
@synthesize command;
@synthesize numericReply;
@synthesize params;

- (id)init
{
	self = [super init];
	if (self) {
		[self parseLine:@""];
	}
	return self;
}

- (id)initWithLine:(NSString*)line
{
	self = [super init];
	if (self) {
		[self parseLine:line];
	}
	return self;
}

- (void)dealloc
{
	[sender release];
	[command release];
	[params release];
	[super dealloc];
}

- (void)parseLine:(NSString*)line
{
	[sender release];
	[command release];
	[params release];
	
	sender = [IRCPrefix new];
	command = @"";
	params = [NSMutableArray new];
	
	NSMutableString* s = [line mutableCopy];
	
	if ([s hasPrefix:@":"]) {
		NSString* t = [s getToken];
		t = [t substringFromIndex:1];
		sender.raw = t;
		
		int i = [t findCharacter:'!'];
		if (i < 0) {
			sender.nick = t;
			sender.isServer = YES;
		}
		else {
			sender.nick = [t substringToIndex:i];
			t = [t substringFromIndex:i+1];
			
			i = [t findCharacter:'@'];
			if (i >= 0) {
				sender.user = [t substringToIndex:i];
				sender.address = [t substringFromIndex:i+1];
			}
		}
	}
	
	command = [[[s getToken] uppercaseString] retain];
	numericReply = [command intValue];
	
	while (!s.isEmpty) {
		if ([s hasPrefix:@":"]) {
			[params addObject:[s substringFromIndex:1]];
			break;
		}
		else {
			[params addObject:[s getToken]];
		}
	}
	
	[s release];
}

- (NSString*)paramAt:(int)index
{
	if (index < params.count) {
		return [params objectAtIndex:index];
	}
	else {
		return @"";
	}
}

- (NSString*)sequence
{
	return [self sequence:0];
}

- (NSString*)sequence:(int)index
{
	NSMutableString* s = [NSMutableString string];
	
	int count = params.count;
	for (int i=index; i<count; i++) {
		NSString* e = [params objectAtIndex:i];
		if (i != index) [s appendString:@" "];
		[s appendString:e];
	}
	
	return s;
}

- (NSString*)description
{
	NSMutableString* ms = [NSMutableString string];
	[ms appendString:@"<IRCMessage "];
	[ms appendString:command];
	for (NSString* s in params) {
		[ms appendString:@" "];
		[ms appendString:s];
	}
	[ms appendString:@">"];
	return ms;
}

@end
