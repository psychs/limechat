// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "IRCSendingMessage.h"
#import "IRC.h"


@implementation IRCSendingMessage

@synthesize command;
@synthesize params;
@synthesize penalty;
@synthesize completeColon;

- (id)initWithCommand:(NSString*)aCommand
{
	if (self = [super init]) {
		command = [[aCommand uppercaseString] retain];
		penalty = IRC_PENALTY_NORMAL;
		completeColon = YES;
		params = [NSMutableArray new];
	}
	return self;
}

- (void)dealloc
{
	[command release];
	[params release];
	[super dealloc];
}

- (void)addParameter:(NSString*)parameter
{
	[params addObject:parameter];
}

- (NSString*)string
{
	if (!string) {
		BOOL forceCompleteColon = NO;
		
		if ([command isEqualToString:PRIVMSG] ||[command isEqualToString:NOTICE]) {
			forceCompleteColon = YES;
		}
		else if ([command isEqualToString:NICK]
				 || [command isEqualToString:MODE]
				 || [command isEqualToString:JOIN]
				 || [command isEqualToString:NAMES]
				 || [command isEqualToString:WHO]
				 || [command isEqualToString:LIST]
				 || [command isEqualToString:INVITE]
				 || [command isEqualToString:WHOIS]
				 || [command isEqualToString:WHOWAS]
				 || [command isEqualToString:ISON]
				 || [command isEqualToString:USER]) {
			completeColon = NO;
		}
		
		NSMutableString* d = [NSMutableString new];
		
		[d appendString:command];
		
		int count = [params count];
		if (count > 0) {
			for (int i=0; i<count-1; ++i) {
				NSString* s = [params objectAtIndex:i];
				[d appendString:@" "];
				[d appendString:s];
			}
			
			[d appendString:@" "];
			NSString* s = [params objectAtIndex:count-1];
			int len = s.length;
			BOOL firstColonOrSpace = NO;
			if (len > 0) {
				UniChar c = [s characterAtIndex:0];
				firstColonOrSpace = (c == ' ' || c == ':');
			}
			
			if (forceCompleteColon || completeColon && (s.length == 0 || firstColonOrSpace)) {
				[d appendString:@":"];
			}
			[d appendString:s];
		}
		
		[d appendString:@"\r\n"];
		
		string = d;
	}
	return string;
}

@end
