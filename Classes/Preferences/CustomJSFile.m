// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "CustomJSFile.h"


@implementation CustomJSFile

- (id)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)setFileName:(NSString *)value
{
    _fileName = value;
    [self reload];
}

- (void)reload
{
    NSData* data = [NSData dataWithContentsOfFile:_fileName];
    _content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

@end
