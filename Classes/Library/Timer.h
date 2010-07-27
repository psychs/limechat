// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

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
