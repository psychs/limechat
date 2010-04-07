// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import <Cocoa/Cocoa.h>
#import "HotKeyManager.h"


@interface LimeChatApplication : NSApplication
{
	HotKeyManager* hotkey;
}

- (void)registerHotKey:(int)keyCode modifierFlags:(NSUInteger)modFlags;
- (void)unregisterHotKey;

@end


@interface NSObject (LimeChatApplicationDelegate)
- (void)applicationDidReceiveHotKey:(id)sender;
@end
