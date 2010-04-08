// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "IRCUser.h"
#import "NSStringHelper.h"


#define COLOR_NUMBER_MAX	16


@implementation IRCUser

@synthesize nick;
@synthesize canonicalNick;
@synthesize username;
@synthesize address;
@synthesize q;
@synthesize a;
@synthesize o;
@synthesize h;
@synthesize v;
@synthesize isMyself;

- (id)init
{
	if (self = [super init]) {
		colorNumber = -1;
	}
	return self;
}

- (void)dealloc
{
	[nick release];
	[canonicalNick release];
	[username release];
	[address release];
	[super dealloc];
}

- (void)setNick:(NSString *)value
{
	if (nick != value) {
		[nick release];
		nick = [value retain];
		
		[canonicalNick release];
		canonicalNick = [[nick canonicalName] retain];
	}
}

- (char)mark
{
	if (q) return '~';
	if (a) return '&';
	if (o) return '@';
	if (h) return '%';
	if (v) return '+';
	return ' ';
}

- (BOOL)isOp
{
	return o || a || q;
}

//@@@ for ruby code
- (BOOL)op
{
	return [self isOp];
}

- (int)colorNumber
{
	if (colorNumber < 0) {
		colorNumber = CFHash(canonicalNick) % COLOR_NUMBER_MAX;
	}
	return colorNumber;
}

- (CGFloat)weight
{
	return 0;
}

- (void)outgoingConversation
{
}

- (void)incomingConversation
{
}

- (void)conversation
{
}

- (void)decayConversation
{
}

- (BOOL)isEqual:(id)other
{
	if (![other isKindOfClass:[IRCUser class]]) return NO;
	IRCUser* u = other;
	return [nick caseInsensitiveCompare:u.nick] == NSOrderedSame;
}

- (NSComparisonResult)compare:(IRCUser*)other
{
	if (isMyself != other.isMyself) {
		return isMyself ? NSOrderedAscending : NSOrderedDescending;
	}
	else if (q != other.q) {
		return q ? NSOrderedAscending : NSOrderedDescending;
	}
	else if (q) {
		return [nick caseInsensitiveCompare:other.nick];
	}
	else if (a != other.a) {
		return a ? NSOrderedAscending : NSOrderedDescending;
	}
	else if (a) {
		return [nick caseInsensitiveCompare:other.nick];
	}
	else if (o != other.o) {
		return o ? NSOrderedAscending : NSOrderedDescending;
	}
	else if (o) {
		return [nick caseInsensitiveCompare:other.nick];
	}
	else if (h != other.h) {
		return h ? NSOrderedAscending : NSOrderedDescending;
	}
	else if (h) {
		return [nick caseInsensitiveCompare:other.nick];
	}
	else if (v != other.v) {
		return v ? NSOrderedAscending : NSOrderedDescending;
	}
	else {
		return [nick caseInsensitiveCompare:other.nick];
	}
}

- (NSString*)description
{
	return [NSString stringWithFormat:@"<IRCUser %c%@>", self.mark, nick];
}

@end
