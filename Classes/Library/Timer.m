// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "Timer.h"


@implementation Timer

@synthesize delegate;
@synthesize reqeat;
@synthesize selector;

- (id)init
{
	self = [super init];
	if (self) {
		reqeat = YES;
		selector = @selector(timerOnTimer:);
	}
	return self;
}

- (void)dealloc
{
	[timer release];
	[super dealloc];
}

- (BOOL)isActive
{
	return timer != nil;
}

- (void)start:(NSTimeInterval)interval
{
	[self stop];
	
	timer = [[NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(onTimer:) userInfo:nil repeats:reqeat] retain];
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSEventTrackingRunLoopMode];
}

- (void)stop
{
	[[self retain] autorelease];
	
	[timer invalidate];
	[timer release];
	timer = nil;
}

- (void)onTimer:(id)sender
{
	if (!self.isActive) return;
	
	if (!reqeat) {
		[self stop];
	}
	
	if ([delegate respondsToSelector:selector]) {
		[delegate performSelector:selector withObject:self];
	}
}

@end
