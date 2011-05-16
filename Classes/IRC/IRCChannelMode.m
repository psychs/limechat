// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

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
	self = [super init];
	if (self) {
		k = @"";
	}
	return self;
}

- (id)initWithChannelMode:(IRCChannelMode*)other
{
	[self init];
	
	isupport = [other.isupport retain];
	a = other.a;
	i = other.i;
	m = other.m;
	n = other.n;
	p = other.p;
	q = other.q;
	r = other.r;
	s = other.s;
	t = other.t;
	l = other.l;
	k = [other.k retain];
	
	return self;
}

- (void)dealloc
{
	[isupport release];
	[k release];
	[super dealloc];
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
	return [[IRCChannelMode allocWithZone:zone] initWithChannelMode:self];
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
					[k autorelease];
					k = plus ? param : @"";
					[k retain];
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

- (NSString*)getChangeCommand:(IRCChannelMode*)mode
{
	NSMutableString* str = [NSMutableString string];
	NSMutableString* trail = [NSMutableString string];
	
	if (a != mode.a) {
		[str appendString:a ? @"-a" : @"+a"];
	}
	if (i != mode.i) {
		[str appendString:i ? @"-i" : @"+i"];
	}
	if (m != mode.m) {
		[str appendString:m ? @"-m" : @"+m"];
	}
	if (n != mode.n) {
		[str appendString:n ? @"-n" : @"+n"];
	}
	if (p != mode.p) {
		[str appendString:p ? @"-p" : @"+p"];
	}
	if (q != mode.q) {
		[str appendString:q ? @"-q" : @"+q"];
	}
	if (r != mode.r) {
		[str appendString:r ? @"-r" : @"+r"];
	}
	if (s != mode.s) {
		[str appendString:s ? @"-s" : @"+s"];
	}
	if (t != mode.t) {
		[str appendString:t ? @"-t" : @"+t"];
	}
	
	if (l != mode.l) {
		if (mode.l > 0) {
			[str appendString:@"+l"];
			[trail appendFormat:@" %d", mode.l];
		}
		else {
			[str appendString:@"-l"];
		}
	}
	
	if (![k isEqualToString:mode.k]) {
		if (mode.k.length) {
			[str appendString:@"+k"];
			[trail appendFormat:@" %@", mode.k];
		}
		else if (k.length) {
			[str appendString:@"-k"];
			[trail appendFormat:@" %@", k];
		}
	}
	
	return [str stringByAppendingString:trail];
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
