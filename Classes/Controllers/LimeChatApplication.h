// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

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
