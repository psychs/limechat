// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "IRCWorldConfig.h"
#import "IRCClientConfig.h"
#import "NSDictionaryHelper.h"


@implementation IRCWorldConfig

- (id)init
{
    self = [super init];
    if (self) {
        _clients = [NSMutableArray new];
        _autoOp = [NSMutableArray new];
    }
    return self;
}

- (id)initWithDictionary:(NSDictionary*)dic
{
    self = [self init];
    if (self) {
        NSArray* ary = [dic arrayForKey:@"clients"] ?: [dic arrayForKey:@"units"];

        for (NSDictionary* e in ary) {
            IRCClientConfig* c = [[IRCClientConfig alloc] initWithDictionary:e];
            [_clients addObject:c];
        }

        [_autoOp addObjectsFromArray:[dic arrayForKey:@"autoop"]];
    }
    return self;
}

- (NSMutableDictionary*)dictionaryValue
{
    NSMutableDictionary* dic = [NSMutableDictionary dictionary];

    NSMutableArray* clientAry = [NSMutableArray array];
    for (IRCClientConfig* e in _clients) {
        [clientAry addObject:[e dictionaryValue]];
    }
    [dic setObject:clientAry forKey:@"clients"];

    [dic setObject:_autoOp forKey:@"autoop"];

    return dic;
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
    return [[IRCWorldConfig allocWithZone:zone] initWithDictionary:[self dictionaryValue]];
}

@end
