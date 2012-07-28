// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "UserNotificationController.h"


@implementation UserNotificationController
{
    __weak id<NotificationControllerDelegate> delegate;
}

@synthesize delegate;

- (id)init
{
    self = [super init];
    if (self) {
        [NSUserNotificationCenter defaultUserNotificationCenter].delegate = self;
    }
    return self;
}

- (void)notify:(UserNotificationType)type title:(NSString*)title desc:(NSString*)desc context:(id)context
{
    switch (type) {
        case USER_NOTIFICATION_HIGHLIGHT:
            title = [NSString stringWithFormat:@"Highlight: %@", title];
            break;
        case USER_NOTIFICATION_NEW_TALK:
            title = @"New Private Message";
            break;
        case USER_NOTIFICATION_CHANNEL_MSG:
            break;
        case USER_NOTIFICATION_CHANNEL_NOTICE:
            title = [NSString stringWithFormat:@"Notice: %@", title];
            break;
        case USER_NOTIFICATION_TALK_MSG:
            title = @"Private Message";
            break;
        case USER_NOTIFICATION_TALK_NOTICE:
            title = @"Private Notice";
            break;
        case USER_NOTIFICATION_KICKED:
            title = [NSString stringWithFormat:@"Kicked: %@", title];
            break;
        case USER_NOTIFICATION_INVITED:
            title = [NSString stringWithFormat:@"Invited: %@", title];
            break;
        case USER_NOTIFICATION_LOGIN:
            title = [NSString stringWithFormat:@"Logged in: %@", title];
            break;
        case USER_NOTIFICATION_DISCONNECT:
            title = [NSString stringWithFormat:@"Disconnected: %@", title];
            break;
        case USER_NOTIFICATION_FILE_RECEIVE_REQUEST:
            desc = [NSString stringWithFormat:@"From %@\n%@", title, desc];
            title = @"File receive request";
            context = @"dcc";
            break;
        case USER_NOTIFICATION_FILE_RECEIVE_SUCCESS:
            desc = [NSString stringWithFormat:@"From %@\n%@", title, desc];
            title = @"File receive succeeded";
            context = @"dcc";
            break;
        case USER_NOTIFICATION_FILE_RECEIVE_ERROR:
            desc = [NSString stringWithFormat:@"From %@\n%@", title, desc];
            title = @"File receive failed";
            context = @"dcc";
            break;
        case USER_NOTIFICATION_FILE_SEND_SUCCESS:
            desc = [NSString stringWithFormat:@"To %@\n%@", title, desc];
            title = @"File send succeeded";
            context = @"dcc";
            break;
        case USER_NOTIFICATION_FILE_SEND_ERROR:
            desc = [NSString stringWithFormat:@"To %@\n%@", title, desc];
            title = @"File send failed";
            context = @"dcc";
            break;
        default:
            break;
    }
    
    NSUserNotification* note = [[NSUserNotification new] autorelease];
    note.title = title;
    note.subtitle = desc;
    if (context) {
        note.userInfo = @{@"context": context};
    }
    
    NSUserNotificationCenter* center = [NSUserNotificationCenter defaultUserNotificationCenter];
    [center deliverNotification:note];
}

- (void)userNotificationCenter:(NSUserNotificationCenter*)sender didActivateNotification:(NSUserNotification*)note
{
    [delegate notificationControllerDidActivateNotification:note.userInfo[@"context"]];
}

@end
