// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the new BSD license.

#import <Foundation/Foundation.h>
#import <Carbon/Carbon.h>


@interface HotKeyManager : NSObject
{
	EventHotKeyRef handle;
}

- (BOOL)enabled;
- (BOOL)registerHotKeyCode:(int)keyCode withModifier:(NSUInteger)modifier;
- (void)unregisterHotKey;

@end
