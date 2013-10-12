// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "IgnoreItem.h"
#import "NSDictionaryHelper.h"
#import "NSStringHelper.h"


@implementation IgnoreItem
{
    NSRegularExpression* _nickRegex;
    NSRegularExpression* _textRegex;
}

- (id)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (id)initWithDictionary:(NSDictionary*)dic
{
    self = [self init];
    if (self) {
        _nick = [dic objectForKey:@"nick"];
        _text = [dic objectForKey:@"text"];
        _useRegexForNick = [dic boolForKey:@"useRegexForNick"];
        _useRegexForText = [dic boolForKey:@"useRegexForText"];
        _channels = [dic objectForKey:@"channels"];
    }
    return self;
}

- (NSDictionary*)dictionaryValue
{
    NSMutableDictionary* dic = [NSMutableDictionary dictionary];

    if (_nick) [dic setObject:_nick forKey:@"nick"];
    if (_text) [dic setObject:_text forKey:@"text"];

    [dic setBool:_useRegexForNick forKey:@"useRegexForNick"];
    [dic setBool:_useRegexForText forKey:@"useRegexForText"];

    if (_channels) [dic setObject:_channels forKey:@"channels"];

    return dic;
}

- (BOOL)isEqual:(id)other
{
    if (![other isKindOfClass:[IgnoreItem class]]) {
        return NO;
    }

    IgnoreItem* g = (IgnoreItem*)other;

    if (_useRegexForNick != g.useRegexForNick) {
        return NO;
    }

    if (_useRegexForText != g.useRegexForText) {
        return NO;
    }

    if (_nick && g.nick && ![_nick isEqualNoCase:g.nick]) {
        return NO;
    }

    if (_text && g.text && ![_text isEqualNoCase:g.text]) {
        return NO;
    }

    if ((!_channels || !_channels.count) && (!g.channels || !g.channels.count)) {
        ;
    }
    else {
        if (![_channels isEqualToArray:g.channels]) {
            return NO;
        }
    }

    return YES;
}

- (void)setNick:(NSString *)value
{
    if (![_nick isEqualToString:value]) {
        _nick = value;
        _nickRegex = nil;
    }
}

- (void)setText:(NSString *)value
{
    if (![_text isEqualToString:value]) {
        _text = value;
        _textRegex = nil;
    }
}

- (BOOL)isValid
{
    return _nick.length > 0 || _text.length > 0;
}

- (NSString*)displayNick
{
    if (!_nick || !_nick.length) return @"";
    if (!_useRegexForNick) return _nick;
    return [NSString stringWithFormat:@"/%@/", _nick];
}

- (NSString*)displayText
{
    if (!_text || !_text.length) return @"";
    if (!_useRegexForText) return _text;
    return [NSString stringWithFormat:@"/%@/", _text];
}

- (BOOL)checkIgnore:(NSString*)inputText nick:(NSString*)inputNick channel:(NSString*)channel
{
    // check nick
    if (!inputNick && _nick.length) {
        return NO;
    }

    if (inputNick.length > 0 && _nick.length > 0) {
        if (_useRegexForNick) {
            if (!_nickRegex) {
                _nickRegex = [[NSRegularExpression alloc] initWithPattern:_nick options:NSRegularExpressionCaseInsensitive error:NULL];
            }

            if (_nickRegex) {
                NSRange range = [_nickRegex rangeOfFirstMatchInString:inputNick options:0 range:NSMakeRange(0, inputNick.length)];
                if (!(range.location == 0 && range.length == inputNick.length)) {
                    return NO;
                }
            }
        }
        else {
            if (![inputNick isEqualNoCase:_nick]) {
                return NO;
            }
        }
    }

    // check text
    if (!inputText && _text.length) {
        return NO;
    }

    if (inputText && _text.length > 0) {
        if (_useRegexForText) {
            if (!_textRegex) {
                _textRegex = [[NSRegularExpression alloc] initWithPattern:_text options:NSRegularExpressionCaseInsensitive error:NULL];
            }

            if (_textRegex) {
                NSRange range = [_textRegex rangeOfFirstMatchInString:inputNick options:0 range:NSMakeRange(0, inputText.length)];
                if (!(range.location == 0 && range.length == inputText.length)) {
                    return NO;
                }
            }
        }
        else {
            NSRange range = [inputText rangeOfString:_text options:NSCaseInsensitiveSearch];
            if (range.location == NSNotFound) {
                return NO;
            }
        }
    }

    // check channels
    if (!channel && _channels.count) {
        return NO;
    }

    if (channel && _channels.count) {
        BOOL matched = NO;
        for (NSString* channelName in _channels) {
            NSString* s = channelName;
            if (![s isChannelName]) {
                s = [@"#" stringByAppendingString:s];
            }
            if ([channel isEqualNoCase:s]) {
                matched = YES;
                break;
            }
        }

        if (!matched) {
            return NO;
        }
    }

    return YES;
}

@end
