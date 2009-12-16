// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import <Foundation/Foundation.h>
#import <Carbon/Carbon.h>

@interface HotKeyManager : NSObject
{
	EventHotKeyRef handle;
}

- (BOOL)enabled;
- (BOOL)registerHotKeyCode:(unsigned int)keyCode withModifier:(unsigned int)modifier;
- (void)unregisterHotKey;

@end
