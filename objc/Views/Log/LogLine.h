// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import <Cocoa/Cocoa.h>


typedef enum {
	LOG_LINE_TYPE_SYSTEM,
	LOG_LINE_TYPE_ERROR,
	LOG_LINE_TYPE_REPLY,
	LOG_LINE_TYPE_ERROR_REPLY,
	LOG_LINE_TYPE_DCC_SEND_SEND,
	LOG_LINE_TYPE_DCC_SEND_RECEIVE,
	LOG_LINE_TYPE_PRIVMSG,
	LOG_LINE_TYPE_NOTICE,
	LOG_LINE_TYPE_ACTION,
	LOG_LINE_TYPE_JOIN,
	LOG_LINE_TYPE_PART,
	LOG_LINE_TYPE_KICK,
	LOG_LINE_TYPE_QUIT,
	LOG_LINE_TYPE_KILL,
	LOG_LINE_TYPE_NICK,
	LOG_LINE_TYPE_MODE,
	LOG_LINE_TYPE_TOPIC,
	LOG_LINE_TYPE_INVITE,
	LOG_LINE_TYPE_WALLOPS,
	LOG_LINE_TYPE_DEBUG_SEND,
	LOG_LINE_TYPE_DEBUG_RECEIVE,
} LogLineType;

typedef enum {
	LOG_MEMBER_TYPE_NORMAL,
	LOG_MEMBER_TYPE_MYSELF,
} LogMemberType;


@interface LogLine : NSObject
{
	NSString* time;
	NSString* place;
	NSString* nick;
	NSString* body;
	LogLineType lineType;
	LogMemberType memberType;
	NSString* nickInfo;
	NSString* clickInfo;
	BOOL identified;
	int nickColorNumber;
}

@property (nonatomic, retain) NSString* time;
@property (nonatomic, retain) NSString* place;
@property (nonatomic, retain) NSString* nick;
@property (nonatomic, retain) NSString* body;
@property (nonatomic, assign) LogLineType lineType;
@property (nonatomic, assign) LogMemberType memberType;
@property (nonatomic, retain) NSString* nickInfo;
@property (nonatomic, retain) NSString* clickInfo;
@property (nonatomic, assign) BOOL identified;
@property (nonatomic, assign) int nickColorNumber;

+ (NSString*)lineTypeString:(LogLineType)type;
+ (NSString*)memberTypeString:(LogMemberType)type;

@end
