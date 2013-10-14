// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "SoundWrapper.h"
#import "SoundPlayer.h"
#import "Preferences.h"


@implementation SoundWrapper
{
    UserNotificationType _eventType;
}

- (id)initWithEventType:(UserNotificationType)aEventType
{
    self = [super init];
    if (self) {
        _eventType = aEventType;
    }
    return self;
}

+ (SoundWrapper*)soundWrapperWithEventType:(UserNotificationType)eventType
{
    return [[SoundWrapper alloc] initWithEventType:eventType];
}

- (NSString*)displayName
{
    return [Preferences titleForEvent:_eventType];
}

- (NSString*)sound
{
    NSString* sound = [Preferences soundForEvent:_eventType];

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
    [Preferences setSound:value forEvent:_eventType];
}

- (BOOL)notification
{
    return [Preferences userNotificationEnabledForEvent:_eventType];
}

- (void)setNotification:(BOOL)value
{
    [Preferences setUserNotificationEnabled:value forEvent:_eventType];
}

@end
