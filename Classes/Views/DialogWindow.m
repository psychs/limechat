// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "DialogWindow.h"


@implementation DialogWindow

- (void)sendEvent:(NSEvent *)e
{
	if ([e type] == NSKeyDown) {
		NSInputManager* im = [NSInputManager currentInputManager];
		if (!im || !im.markedRange.length) {
			int k = [e keyCode];
			NSUInteger m = [e modifierFlags];
			BOOL shift = (m & NSShiftKeyMask) != 0;
			BOOL ctrl = (m & NSControlKeyMask) != 0;
			BOOL alt = (m & NSAlternateKeyMask) != 0;
			BOOL cmd = (m & NSCommandKeyMask) != 0;
			
			if (!(shift || ctrl || alt || cmd)) {
				// no mods
				switch (k) {
					case 0x35:	// esc
						[self close];
						return;
				}
			}
		}
	}
	
	[super sendEvent:e];
}

@end
