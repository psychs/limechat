// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "HostResolver.h"


@implementation HostResolver

- (id)initWithDelegate:(id)aDelegate
{
    self = [super init];
    if (self) {
        _delegate = aDelegate;
    }
    return self;
}

- (void)resolve:(NSString*)hostname
{
    if (hostname.length) {
        [NSThread detachNewThreadSelector:@selector(resolveInternal:) toTarget:self withObject:hostname];
    }
}

- (void)resolveInternal:(NSString*)hostname
{
    @autoreleasepool {
        NSHost* host = [NSHost hostWithName:hostname];
        NSArray* info = [NSArray arrayWithObjects:hostname, host, nil];
        [self performSelectorOnMainThread:@selector(hostResolved:) withObject:info waitUntilDone:YES];
    }
}

- (void)hostResolved:(NSArray*)info
{
    if (!_delegate) return;

    if ([info count] == 2) {
        NSHost* host = [info objectAtIndex:1];
        if ([_delegate respondsToSelector:@selector(hostResolver:didResolve:)]) {
            [_delegate hostResolver:self didResolve:host];
        }
    }
    else {
        NSString* hostname = [info objectAtIndex:0];
        if ([_delegate respondsToSelector:@selector(hostResolver:didNotResolve:)]) {
            [_delegate hostResolver:self didNotResolve:hostname];
        }
    }
}

@end
