// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "IRCChannelMode.h"


@implementation IRCChannelMode

@synthesize isupport;
@synthesize a;
@synthesize i;
@synthesize m;
@synthesize n;
@synthesize p;
@synthesize q;
@synthesize r;
@synthesize s;
@synthesize t;
@synthesize l;
@synthesize k;

- (id)init
{
	if (self = [super init]) {
	}
	return self;
}

- (void)dealloc
{
	[isupport release];
	[k release];
	[super dealloc];
}

- (NSString*)k
{
	return k ?: @"";
}

- (void)clear
{
	a = i = m = n = p = q = r = s = t = NO;
	l = 0;
	self.k = nil;
}

- (NSArray*)update:(NSString*)str
{
	NSArray* ary = [isupport parseMode:str];
	for (IRCModeInfo* h in ary) {
		if (h.op) continue;
		unsigned char mode = h.mode;
		BOOL plus = h.plus;
		if (h.simpleMode) {
			switch (mode) {
				case 'a': a = plus; break;
				case 'i': i = plus; break;
				case 'm': m = plus; break;
				case 'n': n = plus; break;
				case 'p': p = plus; break;
				case 'q': q = plus; break;
				case 'r': r = plus; break;
				case 's': s = plus; break;
				case 't': t = plus; break;
			}
		}
		else {
			switch (mode) {
				case 'k':
				{
					NSString* param = h.param ?: @"";
					k = plus ? param : @"";
					break;
				}
				case 'l':
					if (plus) {
						NSString* param = h.param;
						l = [param intValue];
					}
					else {
						l = 0;
					}
					break;
			}
		}
	}
	return ary;
}

- (NSString*)format:(BOOL)maskK
{
	NSMutableString* str = [NSMutableString string];
	NSMutableString* trail = [NSMutableString string];
	
	if (p) [str appendString:@"p"];
	if (s) [str appendString:@"s"];
	if (m) [str appendString:@"m"];
	if (n) [str appendString:@"n"];
	if (t) [str appendString:@"t"];
	if (i) [str appendString:@"i"];
	if (a) [str appendString:@"a"];
	if (q) [str appendString:@"q"];
	if (r) [str appendString:@"r"];
	
	if (str.length) [str insertString:@"+" atIndex:0];
	
	if (l > 0) {
		[str appendString:@"+l"];
		[trail appendFormat:@" %d", l];
	}
	
	if (k && k.length) {
		[str appendString:@"+k"];
		if (!maskK) [trail appendFormat:@" %@", k];
	}
	
	[str appendString:trail];
	return str;
}

- (NSString*)string
{
	return [self format:NO];
}

- (NSString*)titleString
{
	return [self format:YES];
}

@end
