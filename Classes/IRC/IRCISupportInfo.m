// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "IRCISupportInfo.h"
#import "NSStringHelper.h"
#import "NSDictionaryHelper.h"


#define ISUPPORT_SUFFIX @" are supported by this server"
#define OP_VALUE        100


@implementation IRCISupportInfo
{
    unsigned char _modes[MODES_SIZE];
}

- (id)init
{
    self = [super init];
    if (self) {
        _markMap = [NSMutableDictionary new];
        _modeMap = [NSMutableDictionary new];
        [self reset];
    }
    return self;
}

- (void)reset
{
    [_markMap removeAllObjects];
    [_modeMap removeAllObjects];

    memset(_modes, 0, MODES_SIZE);
    _nickLen = 9;
    _modesCount = 3;

    [self setValue:OP_VALUE forMode:'o'];
    [self setValue:OP_VALUE forMode:'h'];
    [self setValue:OP_VALUE forMode:'v'];
    [self setValue:1 forMode:'b'];
    [self setValue:1 forMode:'e'];
    [self setValue:1 forMode:'I'];
    [self setValue:1 forMode:'R'];
    [self setValue:2 forMode:'k'];
    [self setValue:3 forMode:'l'];
    [self setValue:4 forMode:'i'];
    [self setValue:4 forMode:'m'];
    [self setValue:4 forMode:'n'];
    [self setValue:4 forMode:'p'];
    [self setValue:4 forMode:'s'];
    [self setValue:4 forMode:'t'];
    [self setValue:4 forMode:'a'];
    [self setValue:4 forMode:'q'];
    [self setValue:4 forMode:'r'];

    [_markMap setObject:@'o' forKey:@'@'];
    [_markMap setObject:@'h' forKey:@'%'];
    [_markMap setObject:@'v' forKey:@'+'];
    [_modeMap setObject:@'@' forKey:@'o'];
    [_modeMap setObject:@'%' forKey:@'h'];
    [_modeMap setObject:@'+' forKey:@'v'];
}

- (void)update:(NSString*)str
{
    if ([str hasSuffix:ISUPPORT_SUFFIX]) {
        str = [str substringToIndex:str.length - [ISUPPORT_SUFFIX length]];
    }

    NSArray* ary = [str split:@" "];

    for (NSString* s in ary) {
        NSRange r = [s rangeOfString:@"="];
        if (r.location != NSNotFound) {
            NSString* key = [[s substringToIndex:r.location] uppercaseString];
            NSString* value = [s substringFromIndex:NSMaxRange(r)];
            if ([key isEqualToString:@"PREFIX"]) {
                [self parsePrefix:value];
            }
            else if ([key isEqualToString:@"CHANMODES"]) {
                [self parseChanmodes:value];
            }
            else if ([key isEqualToString:@"NICKLEN"]) {
                _nickLen = [value intValue];
            }
            else if ([key isEqualToString:@"MODES"]) {
                _modesCount = [value intValue];
            }
        }
    }
}

- (NSArray*)parseMode:(NSString*)str
{
    NSMutableArray* ary = [NSMutableArray array];
    NSMutableString* s = [str mutableCopy];
    BOOL plus = NO;

    while (s.length) {
        NSString* token = [s getToken];
        if (!token.length) break;
        UniChar c = [token characterAtIndex:0];

        if (c == '+' || c == '-') {
            plus = c == '+';
            token = [token substringFromIndex:1];

            int len = token.length;
            for (int i=0; i<len; i++) {
                c = [token characterAtIndex:i];
                switch (c) {
                    case '-':
                        plus = NO;
                        break;
                    case '+':
                        plus = YES;
                        break;
                    default:
                    {
                        int v = [self valueForMode:c];
                        if (v == OP_VALUE) {
                            // op
                            IRCModeInfo* m = [IRCModeInfo modeInfo];
                            m.mode = c;
                            m.plus = plus;
                            m.param = [s getToken];
                            m.op = YES;
                            [ary addObject:m];
                        }
                        else if ([self hasParamForMode:c plus:plus]) {
                            // 1 param
                            IRCModeInfo* m = [IRCModeInfo modeInfo];
                            m.mode = c;
                            m.plus = plus;
                            m.param = [s getToken];
                            [ary addObject:m];
                        }
                        else {
                            // simple mode
                            IRCModeInfo* m = [IRCModeInfo modeInfo];
                            m.mode = c;
                            m.plus = plus;
                            m.simpleMode = (v == 4);
                            [ary addObject:m];
                        }
                        break;
                    }
                }
            }
        }
    }

    return ary;
}

- (BOOL)hasParamForMode:(unsigned char)m plus:(BOOL)plus
{
    switch ([self valueForMode:m]) {
        case 0: return NO;
        case 1: return YES;
        case 2: return YES;
        case 3: return plus;
        case OP_VALUE: return YES;
        default: return NO;
    }
}

- (void)parsePrefix:(NSString*)str
{
    if ([str hasPrefix:@"("]) {
        NSRange r = [str rangeOfString:@")"];
        if (r.location != NSNotFound) {
            [_markMap removeAllObjects];
            [_modeMap removeAllObjects];

            NSString* modeStr = [str substringWithRange:NSMakeRange(1, r.location - 1)];
            NSString* markStr = [str substringFromIndex:NSMaxRange(r)];

            int modeLen = modeStr.length;
            int markLen = markStr.length;
            for (int i=0; i<modeLen; i++) {
                UniChar modeChar = [modeStr characterAtIndex:i];
                [self setValue:OP_VALUE forMode:modeChar];

                if (i < markLen) {
                    UniChar markChar = [markStr characterAtIndex:i];
                    NSNumber* modeNumber = @(modeChar);
                    NSNumber* markNumber = @(markChar);
                    [_markMap setObject:modeNumber forKey:markNumber];
                    [_modeMap setObject:markNumber forKey:modeNumber];
                }
            }
        }
    }
}

- (void)parseChanmodes:(NSString*)str
{
    NSArray* ary = [str split:@","];

    int count = ary.count;
    for (int i=0; i<count; i++) {
        NSString* s = [ary objectAtIndex:i];
        int len = s.length;
        for (int j=0; j<len; j++) {
            UniChar c = [s characterAtIndex:j];
            [self setValue:i+1 forMode:c];
        }
    }
}

- (void)setValue:(int)value forMode:(unsigned char)m
{
    if ('a' <= m && m <= 'z') {
        int n = m - 'a';
        _modes[n] = value;
    }
    else if ('A' <= m && m <= 'Z') {
        int n = m - 'A' + 26;
        _modes[n] = value;
    }
}

- (int)valueForMode:(unsigned char)m
{
    if ('a' <= m && m <= 'z') {
        int n = m - 'a';
        return _modes[n];
    }
    else if ('A' <= m && m <= 'Z') {
        int n = m - 'A' + 26;
        return _modes[n];
    }
    return 0;
}

- (char)modeForMark:(char)mark
{
    NSNumber* mode = [_markMap objectForKey:@(mark)];
    if (mode) {
        return [mode intValue];
    }
    return INVALID_MODE_CHAR;
}

- (char)markForMode:(char)mode
{
    NSNumber* mark = [_modeMap objectForKey:@(mode)];
    if (mark) {
        return [mark intValue];
    }
    return INVALID_MARK_CHAR;
}

@end


@implementation IRCModeInfo

+ (IRCModeInfo*)modeInfo
{
    return [IRCModeInfo new];
}

@end
