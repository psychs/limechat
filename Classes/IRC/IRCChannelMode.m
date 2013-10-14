// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "IRCChannelMode.h"


@implementation IRCChannelMode

- (id)init
{
    self = [super init];
    if (self) {
        _k = @"";
    }
    return self;
}

- (id)initWithChannelMode:(IRCChannelMode*)other
{
    self = [self init];
    if (self) {
        _isupport = other.isupport;
        _a = other.a;
        _i = other.i;
        _m = other.m;
        _n = other.n;
        _p = other.p;
        _q = other.q;
        _r = other.r;
        _s = other.s;
        _t = other.t;
        _l = other.l;
        _k = other.k;
    }
    return self;
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
    return [[IRCChannelMode alloc] initWithChannelMode:self];
}

- (NSString*)k
{
    return _k ?: @"";
}

- (void)clear
{
    _a = _i = _m = _n = _p = _q = _r = _s = _t = NO;
    _l = 0;
    self.k = nil;
}

- (NSArray*)update:(NSString*)str
{
    NSArray* ary = [_isupport parseMode:str];
    for (IRCModeInfo* h in ary) {
        if (h.op) continue;
        unsigned char mode = h.mode;
        BOOL plus = h.plus;
        if (h.simpleMode) {
            switch (mode) {
                case 'a': _a = plus; break;
                case 'i': _i = plus; break;
                case 'm': _m = plus; break;
                case 'n': _n = plus; break;
                case 'p': _p = plus; break;
                case 'q': _q = plus; break;
                case 'r': _r = plus; break;
                case 's': _s = plus; break;
                case 't': _t = plus; break;
            }
        }
        else {
            switch (mode) {
                case 'k':
                {
                    NSString* param = h.param ?: @"";
                    _k = plus ? param : @"";
                    break;
                }
                case 'l':
                    if (plus) {
                        NSString* param = h.param;
                        _l = [param intValue];
                    }
                    else {
                        _l = 0;
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

    if (_a != mode.a) {
        [str appendString:_a ? @"-a" : @"+a"];
    }
    if (_i != mode.i) {
        [str appendString:_i ? @"-i" : @"+i"];
    }
    if (_m != mode.m) {
        [str appendString:_m ? @"-m" : @"+m"];
    }
    if (_n != mode.n) {
        [str appendString:_n ? @"-n" : @"+n"];
    }
    if (_p != mode.p) {
        [str appendString:_p ? @"-p" : @"+p"];
    }
    if (_q != mode.q) {
        [str appendString:_q ? @"-q" : @"+q"];
    }
    if (_r != mode.r) {
        [str appendString:_r ? @"-r" : @"+r"];
    }
    if (_s != mode.s) {
        [str appendString:_s ? @"-s" : @"+s"];
    }
    if (_t != mode.t) {
        [str appendString:_t ? @"-t" : @"+t"];
    }

    if (_l != mode.l) {
        if (mode.l > 0) {
            [str appendString:@"+l"];
            [trail appendFormat:@" %d", mode.l];
        }
        else {
            [str appendString:@"-l"];
        }
    }

    if (![_k isEqualToString:mode.k]) {
        if (mode.k.length) {
            [str appendString:@"+k"];
            [trail appendFormat:@" %@", mode.k];
        }
        else if (_k.length) {
            [str appendString:@"-k"];
            [trail appendFormat:@" %@", _k];
        }
    }

    return [str stringByAppendingString:trail];
}

- (NSString*)format:(BOOL)maskK
{
    NSMutableString* str = [NSMutableString string];
    NSMutableString* trail = [NSMutableString string];

    if (_p) [str appendString:@"p"];
    if (_s) [str appendString:@"s"];
    if (_m) [str appendString:@"m"];
    if (_n) [str appendString:@"n"];
    if (_t) [str appendString:@"t"];
    if (_i) [str appendString:@"i"];
    if (_a) [str appendString:@"a"];
    if (_q) [str appendString:@"q"];
    if (_r) [str appendString:@"r"];

    if (str.length) [str insertString:@"+" atIndex:0];

    if (_l > 0) {
        [str appendString:@"+l"];
        [trail appendFormat:@" %d", _l];
    }

    if (_k && _k.length) {
        [str appendString:@"+k"];
        if (!maskK) [trail appendFormat:@" %@", _k];
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
