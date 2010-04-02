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
