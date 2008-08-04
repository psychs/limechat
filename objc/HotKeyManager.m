// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "HotKeyManager.h"

@implementation HotKeyManager

- (void)dealloc
{
	[self unregisterHotKey];
	[super dealloc];
}

- (BOOL)registerHotKeyCode:(unsigned int)keyCode withModifier:(unsigned int)modifier
{
	static UInt32 serial = 0;
	
	[self unregisterHotKey];
	
	UInt32 mod = 0;
	if (modifier & NSShiftKeyMask) { mod |= shiftKey; }
	if (modifier & NSControlKeyMask) { mod |= controlKey; }
	if (modifier & NSCommandKeyMask) { mod |= cmdKey; }
	if (modifier & NSAlternateKeyMask) { mod |= optionKey; }
	
	EventHotKeyID keyId = {'LmCt', serial++};
	
	OSStatus status = RegisterEventHotKey(keyCode, mod, keyId, GetApplicationEventTarget(), 0, &handle);
	return status == noErr;
}

- (void)unregisterHotKey
{
	if (handle) {
		UnregisterEventHotKey(handle);
		handle = 0;
	}
}

@end
