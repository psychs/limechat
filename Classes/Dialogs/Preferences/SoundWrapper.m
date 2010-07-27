// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "SoundWrapper.h"
#import "SoundPlayer.h"
#import "Preferences.h"


@implementation SoundWrapper

- (id)initWithEventType:(GrowlNotificationType)aEventType
{
	if (self = [super init]) {
		eventType = aEventType;
	}
	return self;
}

+ (SoundWrapper*)soundWrapperWithEventType:(GrowlNotificationType)eventType
{
	return [[[SoundWrapper alloc] initWithEventType:eventType] autorelease];
}

- (void)dealloc
{
	[super dealloc];
}

- (NSString*)displayName
{
	return [Preferences titleForEvent:eventType];
}

- (NSString*)sound
{
	NSString* sound = [Preferences soundForEvent:eventType];
	
	if (sound.length == 0) {
		return EMPTY_SOUND;
	}
	else {
		return sound;
	}
}

- (void)setSound:(NSString *)value
{
	if ([value isEqualToString:EMPTY_SOUND]) {
		value = @"";
	}
	
	if (value.length) {
		[SoundPlayer play:value];
	}
	[Preferences setSound:value forEvent:eventType];
}

- (BOOL)growl
{
	return [Preferences growlEnabledForEvent:eventType];
}

- (void)setGrowl:(BOOL)value
{
	[Preferences setGrowlEnabled:value forEvent:eventType];
}

- (BOOL)growlSticky
{
	return [Preferences growlStickyForEvent:eventType];
}

- (void)setGrowlSticky:(BOOL)value
{
	[Preferences setGrowlSticky:value forEvent:eventType];
}

@end
