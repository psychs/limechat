// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "IRCUser.h"
#import "NSStringHelper.h"


#define COLOR_NUMBER_MAX    16


@implementation IRCUser
{
    int _colorNumber;
    CFAbsoluteTime _lastFadedWeights;
}

- (id)init
{
    self = [super init];
    if (self) {
        _colorNumber = -1;
        _lastFadedWeights = CFAbsoluteTimeGetCurrent();
    }
    return self;
}

- (void)setNick:(NSString *)value
{
    if (_nick != value) {
        _nick = value;
        _canonicalNick = [_nick canonicalName];
    }
}

- (char)mark
{
    if (_isupport) {
        char mode = INVALID_MODE_CHAR;
        if (_q) {
            mode = 'q';
        }
        else if (_a) {
            mode = 'a';
        }
        else if (_o) {
            mode = 'o';
        }
        else if (_h) {
            mode = 'h';
        }
        else if (_v) {
            mode = 'v';
        }
        return [_isupport markForMode:mode];
    }
    else {
        if (_q) return '~';
        if (_a) return '&';
        if (_o) return '@';
        if (_h) return '%';
        if (_v) return '+';
        return INVALID_MARK_CHAR;
    }
}

- (BOOL)isOp
{
    return _o || _a || _q;
}

- (int)colorNumber
{
    if (_colorNumber < 0) {
        _colorNumber = CFHash((__bridge CFStringRef)(_canonicalNick)) % COLOR_NUMBER_MAX;
    }
    return _colorNumber;
}

- (BOOL)hasMode:(char)mode
{
    switch (mode) {
        case 'q': return _q;
        case 'a': return _a;
        case 'o': return _o;
        case 'h': return _h;
        case 'v': return _v;
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
    return _incomingWeight + _outgoingWeight;
}

- (void)outgoingConversation
{
    CGFloat change = (_outgoingWeight == 0) ? 20 : 5;
    _outgoingWeight += change;
}

- (void)incomingConversation
{
    CGFloat change = (_incomingWeight == 0) ? 100 : 20;
    _incomingWeight += change;
}

- (void)conversation
{
    CGFloat change = (_outgoingWeight == 0) ? 4 : 1;
    _outgoingWeight += change;
}

// make our conversations decay overtime based on a half-life of one minute
- (void)decayConversation
{
    // we half-life the conversation every minute
    CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
    CGFloat minutes = (now - _lastFadedWeights) / 60;

    if (minutes > 1) {
        _lastFadedWeights = now;
        if (_incomingWeight > 0) {
            _incomingWeight /= (pow(2, minutes));
        }
        if (_outgoingWeight > 0) {
            _outgoingWeight /= (pow(2, minutes));
        }
    }
}

- (BOOL)isEqual:(id)other
{
    if (![other isKindOfClass:[IRCUser class]]) return NO;
    IRCUser* u = other;
    return [_nick caseInsensitiveCompare:u.nick] == NSOrderedSame;
}

- (NSComparisonResult)compare:(IRCUser*)other
{
    if (_isMyself != other.isMyself) {
        return _isMyself ? NSOrderedAscending : NSOrderedDescending;
    }
    else if (_q != other.q) {
        return _q ? NSOrderedAscending : NSOrderedDescending;
    }
    else if (_q) {
        return [_nick caseInsensitiveCompare:other.nick];
    }
    else if (_a != other.a) {
        return _a ? NSOrderedAscending : NSOrderedDescending;
    }
    else if (_a) {
        return [_nick caseInsensitiveCompare:other.nick];
    }
    else if (_o != other.o) {
        return _o ? NSOrderedAscending : NSOrderedDescending;
    }
    else if (_o) {
        return [_nick caseInsensitiveCompare:other.nick];
    }
    else if (_h != other.h) {
        return _h ? NSOrderedAscending : NSOrderedDescending;
    }
    else if (_h) {
        return [_nick caseInsensitiveCompare:other.nick];
    }
    else if (_v != other.v) {
        return _v ? NSOrderedAscending : NSOrderedDescending;
    }
    else {
        return [_nick caseInsensitiveCompare:other.nick];
    }
}

- (NSComparisonResult)compareUsingWeights:(IRCUser*)other
{
    CGFloat mine = self.weight;
    CGFloat others = other.weight;

    if (mine > others) return NSOrderedAscending;
    if (mine < others) return NSOrderedDescending;
    return [_canonicalNick compare:other.canonicalNick];
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"<IRCUser %c%@>", self.mark, _nick];
}

@end
