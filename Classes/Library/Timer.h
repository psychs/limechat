// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Cocoa/Cocoa.h>


@interface Timer : NSObject

@property (nonatomic, weak) id delegate;
@property (nonatomic) BOOL reqeat;
@property (nonatomic) SEL selector;
@property (nonatomic, readonly) BOOL isActive;

- (void)start:(NSTimeInterval)interval;
- (void)stop;

@end


@interface NSObject (TimerDelegate)
- (void)timerOnTimer:(Timer*)sender;
@end
