// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "Timer.h"


@implementation Timer

@synthesize delegate;
@synthesize selector;

- (id)init
{
	if (self = [super init]) {
		selector = @selector(timerOnTimer:);
	}
	return self;
}

- (void)dealloc
{
	[self stop];
	[super dealloc];
}

- (BOOL)isActive
{
	return timer != nil;
}

- (void)start:(int)interval
{
	[self stop];
	
	timer = [[NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(onTimer:) userInfo:nil repeats:YES] retain];
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSEventTrackingRunLoopMode];
}

- (void)stop
{
	[timer invalidate];
	[timer release];
	timer = nil;
}

- (void)onTimer:(id)sender
{
	if (!self.isActive) return;
	
	if ([delegate respondsToSelector:selector]) {
		[delegate performSelector:selector withObject:self];
	}
}

@end
