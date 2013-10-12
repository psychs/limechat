// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "IRCSendingMessage.h"
#import "IRC.h"


@implementation IRCSendingMessage
{
    NSString* _string;
}

- (id)initWithCommand:(NSString*)aCommand
{
    self = [super init];
    if (self) {
        _command = [aCommand uppercaseString];
        _penalty = IRC_PENALTY_NORMAL;
        _completeColon = YES;
        _params = [NSMutableArray new];
    }
    return self;
}

- (void)addParameter:(NSString*)parameter
{
    [_params addObject:parameter];
}

- (NSString*)string
{
    if (!_string) {
        BOOL forceCompleteColon = NO;

        if ([_command isEqualToString:PRIVMSG] ||[_command isEqualToString:NOTICE]) {
            forceCompleteColon = YES;
        }
        else if ([_command isEqualToString:NICK]
                 || [_command isEqualToString:MODE]
                 || [_command isEqualToString:JOIN]
                 || [_command isEqualToString:NAMES]
                 || [_command isEqualToString:WHO]
                 || [_command isEqualToString:LIST]
                 || [_command isEqualToString:INVITE]
                 || [_command isEqualToString:WHOIS]
                 || [_command isEqualToString:WHOWAS]
                 || [_command isEqualToString:ISON]
                 || [_command isEqualToString:USER]) {
            _completeColon = NO;
        }

        NSMutableString* d = [NSMutableString new];

        [d appendString:_command];

        int count = [_params count];
        if (count > 0) {
            for (int i=0; i<count-1; ++i) {
                NSString* s = [_params objectAtIndex:i];
                [d appendString:@" "];
                [d appendString:s];
            }

            [d appendString:@" "];
            NSString* s = [_params objectAtIndex:count-1];
            int len = s.length;
            BOOL firstColonOrSpace = NO;
            if (len > 0) {
                UniChar c = [s characterAtIndex:0];
                firstColonOrSpace = (c == ' ' || c == ':');
            }

            if (forceCompleteColon || (_completeColon && (s.length == 0 || firstColonOrSpace))) {
                [d appendString:@":"];
            }
            [d appendString:s];
        }

        [d appendString:@"\r\n"];

        _string = d;
    }
    return _string;
}

@end
