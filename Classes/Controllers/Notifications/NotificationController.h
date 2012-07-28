// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Foundation/Foundation.h>


typedef enum {
	GROWL_HIGHLIGHT,
	GROWL_NEW_TALK,
	GROWL_CHANNEL_MSG,
	GROWL_CHANNEL_NOTICE,
	GROWL_TALK_MSG,
	GROWL_TALK_NOTICE,
	GROWL_KICKED,
	GROWL_INVITED,
	GROWL_LOGIN,
	GROWL_DISCONNECT,
	GROWL_FILE_RECEIVE_REQUEST,
	GROWL_FILE_RECEIVE_SUCCESS,
	GROWL_FILE_RECEIVE_ERROR,
	GROWL_FILE_SEND_SUCCESS,
	GROWL_FILE_SEND_ERROR,
	GROWL_COUNT,
} GrowlNotificationType;


@protocol NotificationController <NSObject>

@property (nonatomic, weak) id delegate;

- (void)notify:(GrowlNotificationType)type title:(NSString*)title desc:(NSString*)desc context:(id)context;

@end
