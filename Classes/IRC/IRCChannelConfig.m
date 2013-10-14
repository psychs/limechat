// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "IRCChannelConfig.h"
#import "NSDictionaryHelper.h"


@implementation IRCChannelConfig

- (id)init
{
    self = [super init];
    if (self) {
        _type = CHANNEL_TYPE_CHANNEL;
        _autoOp = [NSMutableArray new];

        _autoJoin = YES;
        _logToConsole = YES;
        _notify = YES;

        _name = @"";
        _password = @"";
        _mode = @"+sn";
        _topic = @"";
    }
    return self;
}

- (id)initWithDictionary:(NSDictionary*)dic
{
    self = [self init];
    if (self) {
        _type = [dic intForKey:@"type"];

        _name = [dic stringForKey:@"name"] ?: @"";
        _password = [dic stringForKey:@"password"] ?: @"";

        _autoJoin = [dic boolForKey:@"auto_join"];
        _logToConsole = [dic boolForKey:@"console"];
        if ([dic objectForKey:@"notify"]) {
            _notify = [dic boolForKey:@"notify"];
        } else {
            _notify = [dic boolForKey:@"growl"];
        }

        _mode = [dic stringForKey:@"mode"] ?: @"";
        _topic = [dic stringForKey:@"topic"] ?: @"";

        [_autoOp addObjectsFromArray:[dic arrayForKey:@"autoop"]];
    }
    return self;
}

- (NSMutableDictionary*)dictionaryValue
{
    NSMutableDictionary* dic = [NSMutableDictionary dictionary];

    [dic setInt:_type forKey:@"type"];

    if (_name) [dic setObject:_name forKey:@"name"];
    if (_password) [dic setObject:_password forKey:@"password"];

    [dic setBool:_autoJoin forKey:@"auto_join"];
    [dic setBool:_logToConsole forKey:@"console"];
    [dic setBool:_notify forKey:@"notify"];

    if (_mode) [dic setObject:_mode forKey:@"mode"];
    if (_topic) [dic setObject:_topic forKey:@"topic"];

    if (_autoOp) [dic setObject:_autoOp forKey:@"autoop"];

    return dic;
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
    return [[IRCChannelConfig alloc] initWithDictionary:[self dictionaryValue]];
}

@end
