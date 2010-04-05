// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "LogLine.h"


@implementation LogLine

@synthesize time;
@synthesize place;
@synthesize nick;
@synthesize body;
@synthesize lineType;
@synthesize memberType;
@synthesize nickInfo;
@synthesize clickInfo;
@synthesize identified;
@synthesize nickColorNumber;

- (id)init
{
	if (self = [super init]) {
	}
	return self;
}

- (void)dealloc
{
	[time release];
	[place release];
	[nick release];
	[body release];
	[nickInfo release];
	[clickInfo release];
	[super dealloc];
}

+ (NSString*)lineTypeString:(LogLineType)type
{
	switch (type) {
		case LOG_LINE_TYPE_SYSTEM: return @"system";
		case LOG_LINE_TYPE_ERROR: return @"error";
		case LOG_LINE_TYPE_REPLY: return @"reply";
		case LOG_LINE_TYPE_ERROR_REPLY: return @"error_reply";
		case LOG_LINE_TYPE_DCC_SEND_SEND: return @"dcc_send_send";
		case LOG_LINE_TYPE_DCC_SEND_RECEIVE: return @"dcc_send_receive";
		case LOG_LINE_TYPE_PRIVMSG: return @"privmsg";
		case LOG_LINE_TYPE_NOTICE: return @"notice";
		case LOG_LINE_TYPE_ACTION: return @"action";
		case LOG_LINE_TYPE_JOIN: return @"join";
		case LOG_LINE_TYPE_PART: return @"part";
		case LOG_LINE_TYPE_KICK: return @"kick";
		case LOG_LINE_TYPE_QUIT: return @"quit";
		case LOG_LINE_TYPE_KILL: return @"kill";
		case LOG_LINE_TYPE_NICK: return @"nick";
		case LOG_LINE_TYPE_MODE: return @"mode";
		case LOG_LINE_TYPE_TOPIC: return @"topic";
		case LOG_LINE_TYPE_INVITE: return @"invite";
		case LOG_LINE_TYPE_WALLOPS: return @"wallops";
		case LOG_LINE_TYPE_DEBUG_SEND: return @"debug_send";
		case LOG_LINE_TYPE_DEBUG_RECEIVE: return @"debug_receive";
	}
	return @"";
}

+ (NSString*)memberTypeString:(LogMemberType)type
{
	switch (type) {
		case LOG_MEMBER_TYPE_NORMAL: return @"normal";
		case LOG_MEMBER_TYPE_MYSELF: return @"myself";
	}
	return @"";
}

@end
