// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "InputHistory.h"


#define INPUT_HISTORY_MAX   50


@implementation InputHistory
{
    NSMutableArray* _buf;
    int _pos;
}

- (id)init
{
    self = [super init];
    if (self) {
        _buf = [NSMutableArray new];
    }
    return self;
}

- (void)add:(NSString*)s
{
    _pos = _buf.count;
    if (s.length == 0) return;
    if ([[_buf lastObject] isEqualToString:s]) return;

    [_buf addObject:s];

    if (_buf.count > INPUT_HISTORY_MAX) {
        [_buf removeObjectAtIndex:0];
    }
    _pos = _buf.count;
}

- (NSString*)up:(NSString*)s
{
    if (s && s.length > 0) {
        NSString* cur = nil;
        if (0 <= _pos && _pos < _buf.count) {
            cur = [_buf objectAtIndex:_pos];
        }

        if (!cur || ![cur isEqualToString:s]) {
            // if the text was modified, add it
            [_buf addObject:s];
            if (_buf.count > INPUT_HISTORY_MAX) {
                [_buf removeObjectAtIndex:0];
                --_pos;
            }
        }
    }

    --_pos;
    if (_pos < 0) {
        _pos = 0;
        return nil;
    }
    else if (0 <= _pos && _pos < _buf.count) {
        return [_buf objectAtIndex:_pos];
    }
    else {
        return @"";
    }
}

- (NSString*)down:(NSString*)s
{
    if (!s || s.length == 0) {
        _pos = _buf.count;
        return nil;
    }

    NSString* cur = nil;
    if (0 <= _pos && _pos < _buf.count) {
        cur = [_buf objectAtIndex:_pos];
    }

    if (!cur || ![cur isEqualToString:s]) {
        // if the text was modified, add it
        [self add:s];
        return @"";
    }
    else {
        ++_pos;
        if (0 <= _pos && _pos < _buf.count) {
            return [_buf objectAtIndex:_pos];
        }
        return @"";
    }
}

@end
