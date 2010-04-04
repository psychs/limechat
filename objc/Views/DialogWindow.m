// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "DialogWindow.h"


@implementation DialogWindow

@synthesize keyDelegate;

- (void)sendEvent:(NSEvent *)e
{
	if (keyDelegate) {
		if ([e type] == NSKeyDown) {
			int k = [e keyCode];
			NSUInteger m = [e modifierFlags];
			BOOL shift = m & NSShiftKeyMask != 0;
			BOOL ctrl = m & NSControlKeyMask != 0;
			BOOL alt = m & NSAlternateKeyMask != 0;
			BOOL cmd = m & NSCommandKeyMask != 0;
			
			if (!shift && !ctrl && !alt && !cmd) {
				// no mods
				switch (k) {
					case 53:	// esc
						if ([keyDelegate respondsToSelector:@selector(dialogWindowEscape)]) {
							[keyDelegate dialogWindowEscape];
						}
						return;
					case 76:	// enter
						if ([keyDelegate respondsToSelector:@selector(dialogWindowEnter)]) {
							[keyDelegate dialogWindowEnter];
						}
						return;
				}
			}
			else if (!shift && !ctrl && !alt && cmd || !shift && ctrl && !alt && !cmd) {
				// no mods
				switch (k) {
					case 125:	// down
						if ([keyDelegate respondsToSelector:@selector(dialogWindowMoveDown)]) {
							[keyDelegate dialogWindowMoveDown];
						}
						return;
					case 126:	// up
						if ([keyDelegate respondsToSelector:@selector(dialogWindowMoveUp)]) {
							[keyDelegate dialogWindowMoveUp];
						}
						return;
				}
			}
		}
	}
	
	[super sendEvent:e];
}

@end
