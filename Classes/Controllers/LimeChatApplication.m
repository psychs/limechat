// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "LimeChatApplication.h"


enum {
	kEventHotKeyPressedSubtype = 6,
	kEventHotKeyReleasedSubtype = 9,
};


@implementation LimeChatApplication

- (id)init
{
	self = [super init];
	if (self) {
#ifndef TARGET_APP_STORE
		// migrate from the old .plist
		CFPreferencesAddSuitePreferencesToApp(kCFPreferencesCurrentApplication, CFSTR("LimeChat"));
#endif
	}
	return self;
}

- (void)dealloc
{
	[hotkey release];
	[super dealloc];
}

- (void)sendEvent:(NSEvent *)e
{
	if ([e type] == NSSystemDefined && [e subtype] == kEventHotKeyPressedSubtype) {
		if (hotkey && [hotkey enabled]) {
			unsigned long long handle = (unsigned long long)hotkey.handle;
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
	if (!hotkey) {
		hotkey = [HotKeyManager new];
	}
	[hotkey unregisterHotKey];
	[hotkey registerHotKeyCode:keyCode withModifier:modFlags];
}

- (void)unregisterHotKey
{
	if (hotkey) {
		[hotkey unregisterHotKey];
	}
}

@end
