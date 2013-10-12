// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "LimeChatApplication.h"
#import "Preferences.h"


enum {
    kEventHotKeyPressedSubtype = 6,
    kEventHotKeyReleasedSubtype = 9,
};


@implementation LimeChatApplication
{
    HotKeyManager* _hotkey;
}

- (id)init
{
    self = [super init];
    if (self) {
        [Preferences migrate];
        [Preferences initPreferences];
    }
    return self;
}

- (void)sendEvent:(NSEvent *)e
{
    if ([e type] == NSSystemDefined && [e subtype] == kEventHotKeyPressedSubtype) {
        if (_hotkey && [_hotkey enabled]) {
            unsigned long long handle = (unsigned long long)_hotkey.handle;
            unsigned long long data1 = [e data1];
            handle &= 0xffffffff;
            data1 &= 0xffffffff;
            if (handle == data1) {
                id delegate = [self delegate];
                if ([delegate respondsToSelector:@selector(applicationDidReceiveHotKey:)]) {
                    [delegate applicationDidReceiveHotKey:self];
                }
            }
        }
    }
    [super sendEvent:e];
}

- (void)registerHotKey:(int)keyCode modifierFlags:(NSUInteger)modFlags
{
    if (!_hotkey) {
        _hotkey = [HotKeyManager new];
    }
    [_hotkey unregisterHotKey];
    [_hotkey registerHotKeyCode:keyCode withModifier:modFlags];
}

- (void)unregisterHotKey
{
    if (_hotkey) {
        [_hotkey unregisterHotKey];
    }
}

@end
