// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "Timer.h"


@implementation Timer
{
    NSTimer* _timer;
}

- (id)init
{
    self = [super init];
    if (self) {
        _reqeat = YES;
        _selector = @selector(timerOnTimer:);
    }
    return self;
}

- (BOOL)isActive
{
    return _timer != nil;
}

- (void)start:(NSTimeInterval)interval
{
    [self stop];

    _timer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(onTimer:) userInfo:nil repeats:_reqeat];
    [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSEventTrackingRunLoopMode];
}

- (void)stop
{
    [_timer invalidate];
    _timer = nil;
}

- (void)onTimer:(id)sender
{
    if (!self.isActive) return;

    if (!_reqeat) {
        [self stop];
    }

    if ([_delegate respondsToSelector:_selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [_delegate performSelector:_selector withObject:self];
#pragma clang diagnostic pop
    }
}

@end
