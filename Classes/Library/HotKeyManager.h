// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Foundation/Foundation.h>
#import <Carbon/Carbon.h>


@interface HotKeyManager : NSObject
{
	EventHotKeyRef handle;
}

@property (nonatomic, readonly) EventHotKeyRef handle;

- (BOOL)enabled;
- (BOOL)registerHotKeyCode:(int)keyCode withModifier:(NSUInteger)modifier;
- (void)unregisterHotKey;

@end
