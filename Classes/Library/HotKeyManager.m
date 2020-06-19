// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "HotKeyManager.h"


@implementation HotKeyManager

- (void)dealloc
{
    [self unregisterHotKey];
}

- (BOOL)enabled
{
    return _handle != 0;
}

- (BOOL)registerHotKeyCode:(int)keyCode withModifier:(NSUInteger)modifier
{
    static UInt32 serial = 0;

    [self unregisterHotKey];

    UInt32 mod = 0;
    if (modifier & NSEventModifierFlagShift) { mod |= shiftKey; }
    if (modifier & NSEventModifierFlagControl) { mod |= controlKey; }
    if (modifier & NSEventModifierFlagCommand) { mod |= cmdKey; }
    if (modifier & NSEventModifierFlagOption) { mod |= optionKey; }

    EventHotKeyID keyId = {'LmCt', serial++};

    OSStatus status = RegisterEventHotKey(keyCode, mod, keyId, GetApplicationEventTarget(), 0, &_handle);
    return status == noErr;
}

- (void)unregisterHotKey
{
    if (_handle) {
        UnregisterEventHotKey(_handle);
        _handle = 0;
    }
}

@end
