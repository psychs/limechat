// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

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
@synthesize keywords;
@synthesize excludeWords;
@synthesize useAvatar;

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
	[keywords release];
	[excludeWords release];
	[super dealloc];
}

+ (NSString*)lineTypeString:(LogLineType)type
{
	switch (type) {
		case LINE_TYPE_SYSTEM: return @"system";
		case LINE_TYPE_ERROR: return @"error";
		case LINE_TYPE_REPLY: return @"reply";
		case LINE_TYPE_ERROR_REPLY: return @"error_reply";
		case LINE_TYPE_DCC_SEND_SEND: return @"dcc_send_send";
		case LINE_TYPE_DCC_SEND_RECEIVE: return @"dcc_send_receive";
		case LINE_TYPE_PRIVMSG: return @"privmsg";
		case LINE_TYPE_NOTICE: return @"notice";
		case LINE_TYPE_ACTION: return @"action";
		case LINE_TYPE_JOIN: return @"join";
		case LINE_TYPE_PART: return @"part";
		case LINE_TYPE_KICK: return @"kick";
		case LINE_TYPE_QUIT: return @"quit";
		case LINE_TYPE_KILL: return @"kill";
		case LINE_TYPE_NICK: return @"nick";
		case LINE_TYPE_MODE: return @"mode";
		case LINE_TYPE_TOPIC: return @"topic";
		case LINE_TYPE_INVITE: return @"invite";
		case LINE_TYPE_WALLOPS: return @"wallops";
		case LINE_TYPE_DEBUG_SEND: return @"debug_send";
		case LINE_TYPE_DEBUG_RECEIVE: return @"debug_receive";
	}
	return @"";
}

+ (NSString*)memberTypeString:(LogMemberType)type
{
	switch (type) {
		case MEMBER_TYPE_NORMAL: return @"normal";
		case MEMBER_TYPE_MYSELF: return @"myself";
	}
	return @"";
}

@end
