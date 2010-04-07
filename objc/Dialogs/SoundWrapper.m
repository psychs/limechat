// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "SoundWrapper.h"
#import "SoundPlayer.h"
#import "Preferences.h"


@implementation SoundWrapper

@synthesize displayName;
@synthesize sound;
@synthesize saveSelector;

- (id)initWithDisplayName:(NSString*)aDisplayName sound:(NSString*)aSound saveSelector:(SEL)aSaveSelector
{
	if (self = [super init]) {
		displayName = [aDisplayName retain];
		sound = [aSound retain];
		saveSelector = aSaveSelector;
	}
	return self;
}

- (void)dealloc
{
	[displayName release];
	[sound release];
	[super dealloc];
}

- (NSString*)sound
{
	if (sound.length == 0) {
		return EMPTY_SOUND;
	}
	else {
		return sound;
	}
}

- (void)setSound:(NSString *)value
{
	if (sound != value) {
		if ([value isEqualToString:EMPTY_SOUND]) {
			value = @"";
		}

		[sound release];
		sound = [value retain];
		
		[NewPreferences performSelector:saveSelector withObject:value];
		[SoundPlayer play:sound];
	}
}

@end
