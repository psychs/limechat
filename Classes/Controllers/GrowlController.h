// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Foundation/Foundation.h>
#import "Growl/Growl.h"


@class IRCWorld;


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


@interface GrowlController : NSObject <GrowlApplicationBridgeDelegate>
{
	IRCWorld* owner;
	id lastClickedContext;
	CFAbsoluteTime lastClickedTime;
}

@property (nonatomic, assign) IRCWorld* owner;

- (void)notify:(GrowlNotificationType)type title:(NSString*)title desc:(NSString*)desc context:(id)context;

@end
