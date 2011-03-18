// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "IRCUser.h"
#import "NSStringHelper.h"


#define COLOR_NUMBER_MAX	16


@interface IRCUser (Private)
- (void)decayConversation;
@end


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
@synthesize incomingWeight;
@synthesize outgoingWeight;

- (id)init
{
	self = [super init];
	if (self) {
		colorNumber = -1;
		lastFadedWeights = CFAbsoluteTimeGetCurrent();
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

- (int)colorNumber
{
	if (colorNumber < 0) {
		colorNumber = CFHash(canonicalNick) % COLOR_NUMBER_MAX;
	}
	return colorNumber;
}

- (BOOL)hasMode:(char)mode
{
	switch (mode) {
		case 'q': return q;
		case 'a': return a;
		case 'o': return o;
		case 'h': return h;
		case 'v': return v;
	}
	return NO;
}

// the weighting system keeps track of who you are talking to
// and who is talking to you... incoming messages are not weighted
// as highly as the messages you send to someone
//
// outgoingConversation is called when someone sends you a message
// incomingConversation is called when you talk to someone
//
// the conventions are probably backwards if you think of them from
// the wrong able, I'm open to suggestions - Josh Goebel

- (CGFloat)weight
{
	[self decayConversation];	// fade the conversation since the last time we spoke
	return incomingWeight + outgoingWeight;
}

- (void)outgoingConversation
{
	CGFloat change = (outgoingWeight == 0) ? 20 : 5;
	outgoingWeight += change;
}

- (void)incomingConversation
{
	CGFloat change = (incomingWeight == 0) ? 100 : 20;
	incomingWeight += change;
}

- (void)conversation
{
	CGFloat change = (outgoingWeight == 0) ? 4 : 1;
	outgoingWeight += change;
}

// make our conversations decay overtime based on a half-life of one minute
- (void)decayConversation
{
	// we half-life the conversation every minute
	CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
	CGFloat minutes = (now - lastFadedWeights) / 60;
	
	if (minutes > 1) {
		lastFadedWeights = now;
		if (incomingWeight > 0) {
			incomingWeight /= (pow(2, minutes));
		}
		if (outgoingWeight > 0) {
			outgoingWeight /= (pow(2, minutes));
		}
	}
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

- (NSComparisonResult)compareUsingWeights:(IRCUser*)other
{
	CGFloat mine = self.weight;
	CGFloat others = other.weight;

	if (mine > others) return NSOrderedAscending;
	if (mine < others) return NSOrderedDescending;
	return [canonicalNick compare:other.canonicalNick];
}

- (NSString*)description
{
	return [NSString stringWithFormat:@"<IRCUser %c%@>", self.mark, nick];
}

@end
