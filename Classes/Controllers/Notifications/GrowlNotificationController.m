// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "GrowlNotificationController.h"
#import "Preferences.h"


#define GROWL_MSG_LOGIN                     @"Logged in"
#define GROWL_MSG_DISCONNECT                @"Disconnected"
#define GROWL_MSG_HIGHLIGHT                 @"Highlight message received"
#define GROWL_MSG_NEW_TALK                  @"New private message started"
#define GROWL_MSG_CHANNEL_MSG               @"Channel message received"
#define GROWL_MSG_CHANNEL_NOTICE            @"Channel notice received"
#define GROWL_MSG_TALK_MSG                  @"Private message received"
#define GROWL_MSG_TALK_NOTICE               @"Private notice received"
#define GROWL_MSG_KICKED                    @"Kicked out from channel"
#define GROWL_MSG_INVITED                   @"Invited to channel"
#define GROWL_MSG_FILE_RECEIVE_REQUEST      @"File receive requested"
#define GROWL_MSG_FILE_RECEIVE_SUCCEEDED    @"File receive succeeded"
#define GROWL_MSG_FILE_RECEIVE_FAILED       @"File receive failed"
#define GROWL_MSG_FILE_SEND_SUCCEEDED       @"File send succeeded"
#define GROWL_NSG_FILE_SEND_FAILED          @"File send failed"

#define CLICK_INTERVAL                      2


@implementation GrowlNotificationController
{
    __weak id<NotificationControllerDelegate> delegate;
    id lastClickedContext;
    CFAbsoluteTime lastClickedTime;
}

@synthesize delegate;

- (id)init
{
    self = [super init];
    if (self) {
        [GrowlApplicationBridge setGrowlDelegate:self];
    }
    return self;
}

- (void)dealloc
{
    [lastClickedContext release];
    [super dealloc];
}

- (void)notify:(UserNotificationType)type title:(NSString*)title desc:(NSString*)desc context:(id)context
{
    int priority = 0;
    BOOL sticky = [Preferences growlStickyForEvent:type];
    NSString* kind = nil;

    switch (type) {
        case USER_NOTIFICATION_HIGHLIGHT:
            kind = GROWL_MSG_HIGHLIGHT;
            priority = 1;
            title = [NSString stringWithFormat:@"Highlight: %@", title];
            break;
        case USER_NOTIFICATION_NEW_TALK:
            kind = GROWL_MSG_NEW_TALK;
            priority = 1;
            title = @"New Private Message";
            break;
        case USER_NOTIFICATION_CHANNEL_MSG:
            kind = GROWL_MSG_CHANNEL_MSG;
            break;
        case USER_NOTIFICATION_CHANNEL_NOTICE:
            kind = GROWL_MSG_CHANNEL_NOTICE;
            title = [NSString stringWithFormat:@"Notice: %@", title];
            break;
        case USER_NOTIFICATION_TALK_MSG:
            kind = GROWL_MSG_TALK_MSG;
            title = @"Private Message";
            break;
        case USER_NOTIFICATION_TALK_NOTICE:
            kind = GROWL_MSG_TALK_NOTICE;
            title = @"Private Notice";
            break;
        case USER_NOTIFICATION_KICKED:
            kind = GROWL_MSG_KICKED;
            title = [NSString stringWithFormat:@"Kicked: %@", title];
            break;
        case USER_NOTIFICATION_INVITED:
            kind = GROWL_MSG_INVITED;
            title = [NSString stringWithFormat:@"Invited: %@", title];
            break;
        case USER_NOTIFICATION_LOGIN:
            kind = GROWL_MSG_LOGIN;
            title = [NSString stringWithFormat:@"Logged in: %@", title];
            break;
        case USER_NOTIFICATION_DISCONNECT:
            kind = GROWL_MSG_DISCONNECT;
            title = [NSString stringWithFormat:@"Disconnected: %@", title];
            break;
        case USER_NOTIFICATION_FILE_RECEIVE_REQUEST:
            kind = GROWL_MSG_FILE_RECEIVE_REQUEST;
            desc = [NSString stringWithFormat:@"From %@\n%@", title, desc];
            title = @"File receive request";
            context = @{USER_NOTIFICATION_DCC_KEY: @YES};
            break;
        case USER_NOTIFICATION_FILE_RECEIVE_SUCCESS:
            kind = GROWL_MSG_FILE_RECEIVE_SUCCEEDED;
            desc = [NSString stringWithFormat:@"From %@\n%@", title, desc];
            title = @"File receive succeeded";
            context = @{USER_NOTIFICATION_DCC_KEY: @YES};
            break;
        case USER_NOTIFICATION_FILE_RECEIVE_ERROR:
            kind = GROWL_MSG_FILE_RECEIVE_FAILED;
            desc = [NSString stringWithFormat:@"From %@\n%@", title, desc];
            title = @"File receive failed";
            context = @{USER_NOTIFICATION_DCC_KEY: @YES};
            break;
        case USER_NOTIFICATION_FILE_SEND_SUCCESS:
            kind = GROWL_MSG_FILE_SEND_SUCCEEDED;
            desc = [NSString stringWithFormat:@"To %@\n%@", title, desc];
            title = @"File send succeeded";
            context = @{USER_NOTIFICATION_DCC_KEY: @YES};
            break;
        case USER_NOTIFICATION_FILE_SEND_ERROR:
            kind = GROWL_NSG_FILE_SEND_FAILED;
            desc = [NSString stringWithFormat:@"To %@\n%@", title, desc];
            title = @"File send failed";
            context = @{USER_NOTIFICATION_DCC_KEY: @YES};
            break;
        default:
            break;
    }

    [GrowlApplicationBridge notifyWithTitle:title description:desc notificationName:kind iconData:nil priority:priority isSticky:sticky clickContext:context];
}

- (NSDictionary*)registrationDictionaryForGrowl
{
    NSArray* all = @[GROWL_MSG_LOGIN, GROWL_MSG_DISCONNECT, GROWL_MSG_HIGHLIGHT,
    GROWL_MSG_NEW_TALK, GROWL_MSG_CHANNEL_MSG, GROWL_MSG_CHANNEL_NOTICE,
    GROWL_MSG_TALK_MSG, GROWL_MSG_TALK_NOTICE, GROWL_MSG_KICKED,
    GROWL_MSG_INVITED, GROWL_MSG_FILE_RECEIVE_REQUEST, GROWL_MSG_FILE_RECEIVE_SUCCEEDED,
    GROWL_MSG_FILE_RECEIVE_FAILED, GROWL_MSG_FILE_SEND_SUCCEEDED, GROWL_NSG_FILE_SEND_FAILED];
    
    NSMutableDictionary* dic = [NSMutableDictionary dictionary];
    dic[GROWL_NOTIFICATIONS_ALL] = all;
    dic[GROWL_NOTIFICATIONS_DEFAULT] = all;
    return dic;
}

- (void)growlNotificationWasClicked:(id)context
{
    CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
    if (now - lastClickedTime < CLICK_INTERVAL) {
        if (lastClickedContext && [lastClickedContext isEqual:context]) {
            return;
        }
    }
    
    lastClickedTime = now;
    [lastClickedContext release];
    lastClickedContext = [context retain];
    
    [delegate notificationControllerDidActivateNotification:lastClickedContext actionButtonClicked:NO];
}

@end
