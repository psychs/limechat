// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Cocoa/Cocoa.h>


typedef enum {
    LINE_TYPE_SYSTEM,
    LINE_TYPE_ERROR,
    LINE_TYPE_REPLY,
    LINE_TYPE_ERROR_REPLY,
    LINE_TYPE_DCC_SEND_SEND,
    LINE_TYPE_DCC_SEND_RECEIVE,
    LINE_TYPE_PRIVMSG,
    LINE_TYPE_NOTICE,
    LINE_TYPE_ACTION,
    LINE_TYPE_JOIN,
    LINE_TYPE_PART,
    LINE_TYPE_KICK,
    LINE_TYPE_QUIT,
    LINE_TYPE_KILL,
    LINE_TYPE_NICK,
    LINE_TYPE_MODE,
    LINE_TYPE_TOPIC,
    LINE_TYPE_INVITE,
    LINE_TYPE_WALLOPS,
    LINE_TYPE_DEBUG_SEND,
    LINE_TYPE_DEBUG_RECEIVE,
} LogLineType;

typedef enum {
    MEMBER_TYPE_NORMAL,
    MEMBER_TYPE_MYSELF,
} LogMemberType;


@interface LogLine : NSObject

@property (nonatomic) NSString* time;
@property (nonatomic) NSString* place;
@property (nonatomic) NSString* nick;
@property (nonatomic) NSString* body;
@property (nonatomic) LogLineType lineType;
@property (nonatomic) LogMemberType memberType;
@property (nonatomic) NSString* nickInfo;
@property (nonatomic) NSString* clickInfo;
@property (nonatomic) BOOL identified;
@property (nonatomic) int nickColorNumber;
@property (nonatomic) NSArray* keywords;
@property (nonatomic) NSArray* excludeWords;
@property (nonatomic) BOOL useAvatar;

+ (NSString*)lineTypeString:(LogLineType)type;
+ (NSString*)memberTypeString:(LogMemberType)type;

@end
