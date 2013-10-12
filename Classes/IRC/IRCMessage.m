// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "IRCMessage.h"
#import "NSDateHelper.h"
#import "NSStringHelper.h"


@implementation IRCMessage

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

- (void)parseLine:(NSString*)line
{
    _sender = [IRCPrefix new];
    _command = @"";
    _timestamp = 0;
    _params = [NSMutableArray new];

    NSMutableString* s = [line mutableCopy];

    while ([s hasPrefix:@"@"]) {
        NSString* t = [s getToken];
        t = [t substringFromIndex:1];

        int i = [t findCharacter:'='];
        if (i < 0) {
            continue;
        }

        NSString* key = [t substringToIndex:i];
        NSString* value = [t substringFromIndex:i+1];

        // Spec is http://ircv3.atheme.org/extensions/server-time-3.2
        // ZNC has supported @t and @time keys and UnixTimestamp and ISO8601 dates
        // in past releases.
        // Attempt to support all previous formats.
        if ([key isEqualToString:@"t"] || [key isEqualToString:@"time"]) {
            if ([value contains:@"-"]) {
                _timestamp = [NSDate timeIntervalFromISO8601String:value];
            }
            else {
                _timestamp = [value longLongValue];
            }
        }
    }

    if (_timestamp == 0) {
        time(&_timestamp);
    }

    if ([s hasPrefix:@":"]) {
        NSString* t = [s getToken];
        t = [t substringFromIndex:1];
        _sender.raw = t;

        int i = [t findCharacter:'!'];
        if (i < 0) {
            _sender.nick = t;
            _sender.isServer = YES;
        }
        else {
            _sender.nick = [t substringToIndex:i];
            t = [t substringFromIndex:i+1];

            i = [t findCharacter:'@'];
            if (i >= 0) {
                _sender.user = [t substringToIndex:i];
                _sender.address = [t substringFromIndex:i+1];
            }
        }
    }

    _command = [[s getToken] uppercaseString];
    _numericReply = [_command intValue];

    while (s.length) {
        if ([s hasPrefix:@":"]) {
            [_params addObject:[s substringFromIndex:1]];
            break;
        }
        else {
            [_params addObject:[s getToken]];
        }
    }
}

- (NSString*)paramAt:(int)index
{
    if (index < _params.count) {
        return [_params objectAtIndex:index];
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

    int count = _params.count;
    for (int i=index; i<count; i++) {
        NSString* e = [_params objectAtIndex:i];
        if (i != index) [s appendString:@" "];
        [s appendString:e];
    }

    return s;
}

- (NSString*)description
{
    NSMutableString* ms = [NSMutableString string];
    [ms appendString:@"<IRCMessage "];
    [ms appendString:_command];
    for (NSString* s in _params) {
        [ms appendString:@" "];
        [ms appendString:s];
    }
    [ms appendString:@">"];
    return ms;
}

@end
