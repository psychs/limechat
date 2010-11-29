// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

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
			id delegate = [self delegate];
			if ([delegate respondsToSelector:@selector(applicationDidReceiveHotKey:)]) {
				[delegate applicationDidReceiveHotKey:self];
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
