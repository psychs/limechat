// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

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
