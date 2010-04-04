// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "SoundPlayer.h"


@implementation SoundPlayer

+ (void)play:(NSString*)name
{
	if (!name || !name.length) return;
	
	if ([name isEqualToString:@"Beep"]) {
		NSBeep();
	}
	else {
		NSSound* sound = [NSSound soundNamed:name];
		if (sound) {
			[sound play];
		}
	}
}

@end
