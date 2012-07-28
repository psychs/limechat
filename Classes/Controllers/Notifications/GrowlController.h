// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Foundation/Foundation.h>
#import "Growl/Growl.h"
#import "NotificationController.h"


@class IRCWorld;


@interface GrowlController : NSObject <GrowlApplicationBridgeDelegate>

@property (nonatomic, weak) IRCWorld* owner;

- (void)notify:(GrowlNotificationType)type title:(NSString*)title desc:(NSString*)desc context:(id)context;

@end
