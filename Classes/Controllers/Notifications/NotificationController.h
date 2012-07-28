// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Foundation/Foundation.h>


typedef enum {
	USER_NOTIFICATION_HIGHLIGHT,
	USER_NOTIFICATION_NEW_TALK,
	USER_NOTIFICATION_CHANNEL_MSG,
	USER_NOTIFICATION_CHANNEL_NOTICE,
	USER_NOTIFICATION_TALK_MSG,
	USER_NOTIFICATION_TALK_NOTICE,
	USER_NOTIFICATION_KICKED,
	USER_NOTIFICATION_INVITED,
	USER_NOTIFICATION_LOGIN,
	USER_NOTIFICATION_DISCONNECT,
	USER_NOTIFICATION_FILE_RECEIVE_REQUEST,
	USER_NOTIFICATION_FILE_RECEIVE_SUCCESS,
	USER_NOTIFICATION_FILE_RECEIVE_ERROR,
	USER_NOTIFICATION_FILE_SEND_SUCCESS,
	USER_NOTIFICATION_FILE_SEND_ERROR,
	USER_NOTIFICATION_COUNT,
} UserNotificationType;


#define USER_NOTIFICATION_DCC_KEY                   @"dcc"
#define USER_NOTIFICATION_CLIENT_ID_KEY             @"clientId"
#define USER_NOTIFICATION_CHANNEL_ID_KEY            @"channelId"
#define USER_NOTIFICATION_INVITED_CHANNEL_NAME_KEY  @"invitedChannelName"


@protocol NotificationControllerDelegate <NSObject>
- (void)notificationControllerDidActivateNotification:(id)context actionButtonClicked:(BOOL)actionButtonClicked;
@end


@protocol NotificationController <NSObject>
@property (nonatomic, weak) id<NotificationControllerDelegate> delegate;
- (void)notify:(UserNotificationType)type title:(NSString*)title desc:(NSString*)desc context:(id)context;
@end
