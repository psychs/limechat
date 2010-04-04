// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import <Cocoa/Cocoa.h>


@interface Timer : NSObject
{
	id delegate;
	
	NSTimer* timer;
}

@property (nonatomic, assign) id delegate;

- (BOOL)active;
- (void)start:(int)interval;
- (void)stop;

@end


@interface NSObject (TimerDelegate)
- (void)timerOnTimer:(Timer*)sender;
@end
