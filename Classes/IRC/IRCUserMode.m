// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "IRCUserMode.h"


@implementation IRCUserMode

@synthesize a;
@synthesize i;
@synthesize r;
@synthesize s;
@synthesize w;
@synthesize o;
@synthesize O;

- (id)init
{
	if (self = [super init]) {
	}
	return self;
}

- (void)dealloc
{
	[super dealloc];
}

- (void)clear
{
	a = i = r = s = w = o = O = NO;
}

- (void)update:(NSString*)str
{
	int len = str.length;
	BOOL plus = NO;
	
	for (int index=0; index<len; ++index) {
		UniChar uc = [str characterAtIndex:index];
		switch (uc) {
			case '+':
				plus = YES;
				break;
			case '-':
				plus = NO;
				break;
			case 'a':
				a = plus;
				break;
			case 'i':
				i = plus;
				break;
			case 'r':
				r = plus;
				break;
			case 's':
				s = plus;
				break;
			case 'w':
				w = plus;
				break;
			case 'o':
				o = plus;
				break;
			case 'O':
				O = plus;
				break;
		}
	}
}

- (NSString*)string
{
	NSMutableString* str = [NSMutableString string];
	
	if (a) [str appendString:@"a"];
	if (i) [str appendString:@"i"];
	if (r) [str appendString:@"r"];
	if (s) [str appendString:@"s"];
	if (w) [str appendString:@"w"];
	if (o) [str appendString:@"o"];
	if (O) [str appendString:@"O"];
	
	if (str.length) [str insertString:@"+" atIndex:0];
	return str;
}

@end
