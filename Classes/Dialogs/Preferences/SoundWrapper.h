// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Cocoa/Cocoa.h>
#import "NotificationController.h"


#define EMPTY_SOUND     @"-"


@interface SoundWrapper : NSObject

@property (nonatomic, readonly) NSString* displayName;
@property (nonatomic) NSString* sound;
@property (nonatomic) BOOL notification;

+ (SoundWrapper*)soundWrapperWithEventType:(UserNotificationType)eventType;

@end
