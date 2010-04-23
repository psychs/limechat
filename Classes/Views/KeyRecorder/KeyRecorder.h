// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the new BSD license.

#import <Cocoa/Cocoa.h>
#import "KeyRecorderCell.h"


@interface KeyRecorder : NSControl
{
	id delegate;
	int keyCode;
	NSUInteger modifierFlags;
	
	BOOL recording;
	BOOL eraseButtonPushed;
	BOOL eraseButtonHighlighted;
}

@property (nonatomic, assign) IBOutlet id delegate;
@property (nonatomic, assign) int keyCode;
@property (nonatomic, assign) NSUInteger modifierFlags;
@property (nonatomic, readonly) BOOL valid;

@end


@interface NSObject (KeyRecorder)
- (void)keyRecorderDidChangeKey:(KeyRecorder*)sender;
@end
