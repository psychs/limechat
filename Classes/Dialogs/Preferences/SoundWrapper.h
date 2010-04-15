// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

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
