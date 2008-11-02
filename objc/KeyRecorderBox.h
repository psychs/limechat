// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import <Cocoa/Cocoa.h>

@interface KeyRecorderBox : NSControl
{
	BOOL valid;
	int currentKeyCode;
	int currentModifierFlags;
  id _delegate;
}

- (id)delegate;
- (void)setDelegate:(id)delegate;
- (BOOL)valid;
- (int)keyCode;
- (int)modifierFlags;
- (void)setKeyCode:(int)aKeyCode modifierFlags:(int)aModifierFlags;

- (void)clearKey;

@end
