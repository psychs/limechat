// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the new BSD license.

#import <Cocoa/Cocoa.h>


@interface Timer : NSObject
{
	id delegate;
	BOOL reqeat;
	SEL selector;
	NSTimer* timer;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, assign) BOOL reqeat;
@property (nonatomic, assign) SEL selector;
@property (nonatomic, readonly) BOOL isActive;

- (void)start:(NSTimeInterval)interval;
- (void)stop;

@end


@interface NSObject (TimerDelegate)
- (void)timerOnTimer:(Timer*)sender;
@end
