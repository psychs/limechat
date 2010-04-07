// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "LimeChatApplication.h"


@implementation LimeChatApplication

- (id)init
{
	if (self = [super init]) {
		// migrate from the old .plist
		CFPreferencesAddSuitePreferencesToApp(kCFPreferencesCurrentApplication, CFSTR("LimeChat"));
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
	if ([e type] == 14 && [e subtype] == 6) {
		if (hotkey && [hotkey enabled]) {
			if ([[self delegate] respondsToSelector:@selector(applicationDidReceiveHotKey:)]) {
				[[self delegate] applicationDidReceiveHotKey:self];
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
