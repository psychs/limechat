// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Cocoa/Cocoa.h>
#import "GrowlController.h"


#define EMPTY_SOUND		@"-"


@interface SoundWrapper : NSObject
{
	GrowlNotificationType eventType;
}

@property (nonatomic, readonly) NSString* displayName;
@property (nonatomic, assign) NSString* sound;
@property (nonatomic, assign) BOOL growl;
@property (nonatomic, assign) BOOL growlSticky;

+ (SoundWrapper*)soundWrapperWithEventType:(GrowlNotificationType)eventType;

@end
