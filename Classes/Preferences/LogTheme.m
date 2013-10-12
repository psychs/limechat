// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "LogTheme.h"


@implementation LogTheme

- (id)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)setFileName:(NSString *)value
{
    if (_fileName != value) {
        _fileName = value;
        _baseUrl = nil;

        if (_fileName) {
            _baseUrl = [NSURL fileURLWithPath:[_fileName stringByDeletingLastPathComponent]];
        }
    }

    [self reload];
}

- (void)reload
{
    _content = nil;

    if (_fileName) {
        _content = [NSString stringWithContentsOfFile:_fileName encoding:NSUTF8StringEncoding error:NULL];
    }
}

@end
