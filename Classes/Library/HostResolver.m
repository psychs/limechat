// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "HostResolver.h"


@implementation HostResolver

+ (dispatch_queue_t)sharedQueue
{
    static dispatch_queue_t sharedQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedQueue = dispatch_queue_create("net.limechat.LimeChat.HostResolver", DISPATCH_QUEUE_CONCURRENT);
    });
    return sharedQueue;
}

- (instancetype)initWithDelegate:(id<HostResolverDelegate>)delegate
{
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

- (void)resolve:(NSString *)hostname
{
    NSString *safeHostname = [hostname copy];

    dispatch_async([[self class] sharedQueue], ^{
        NSHost *host = [NSHost hostWithName:safeHostname];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self hostResolvedWithHost:host hostname:safeHostname];
        });
    });
}

- (void)hostResolvedWithHost:(NSHost *)host hostname:(NSString *)hostname
{
    if (!_delegate) return;

    if (host) {
        if ([_delegate respondsToSelector:@selector(hostResolver:didResolve:)]) {
            [_delegate hostResolver:self didResolve:host];
        }
    } else {
        if ([_delegate respondsToSelector:@selector(hostResolver:didNotResolve:)]) {
            [_delegate hostResolver:self didNotResolve:hostname];
        }
    }
}

@end
