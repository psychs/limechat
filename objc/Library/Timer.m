// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "Timer.h"


@implementation Timer

@synthesize delegate;

- (void)dealloc
{
	[self stop];
	[super dealloc];
}

- (BOOL)active
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
	if ([self active]) {
		if ([delegate respondsToSelector:@selector(timerOnTimer:)]) {
			[delegate timerOnTimer:self];
		}
	}
}

@end
