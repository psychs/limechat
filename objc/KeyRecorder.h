// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import <Cocoa/Cocoa.h>
#import "KeyRecorderCell.h"


@interface KeyRecorder : NSControl
{
	id delegate;
	int keyCode;
	int modifierFlags;
	
	BOOL recording;
	BOOL eraseButtonPushed;
	BOOL eraseButtonHighlighted;
}

@property (nonatomic, assign) IBOutlet id delegate;
@property (nonatomic, assign) int keyCode;
@property (nonatomic, assign) int modifierFlags;
@property (nonatomic, readonly) BOOL valid;

@end


@interface NSObject (KeyRecorder)
- (void)keyRecorderDidChangeKey:(KeyRecorder*)sender;
@end
