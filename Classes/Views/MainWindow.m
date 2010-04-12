// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "MainWindow.h"


@implementation MainWindow

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)windowStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)deferCreation
{
	if (self = [super initWithContentRect:contentRect styleMask:windowStyle backing:bufferingType defer:deferCreation]) {
		keyHandler = [KeyEventHandler new];
	}
	return self;
}

- (void)dealloc
{
	[keyHandler release];
	[super dealloc];
}

- (void)setKeyHandlerTarget:(id)target
{
	[keyHandler setTarget:target];
}

- (void)registerKeyHandler:(SEL)selector key:(int)code modifiers:(NSUInteger)mods
{
	[keyHandler registerSelector:selector key:code modifiers:mods];
}

- (void)registerKeyHandler:(SEL)selector character:(UniChar)c modifiers:(NSUInteger)mods
{
	[keyHandler registerSelector:selector character:c modifiers:mods];
}

- (void)sendEvent:(NSEvent *)e
{
	if ([e type] == NSKeyDown) {
		if ([keyHandler processKeyEvent:e]) {
			return;
		}
	}
	
	[super sendEvent:e];
}

@end
