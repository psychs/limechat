// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "GrowlController.h"
#import "IRCWorld.h"
#import "Preferences.h"


#define GROWL_MSG_LOGIN						@"Logged in"
#define GROWL_MSG_DISCONNECT				@"Disconnected"
#define GROWL_MSG_HIGHLIGHT					@"Highlight message received"
#define GROWL_MSG_NEW_TALK					@"New talk started"
#define GROWL_MSG_CHANNEL_MSG				@"Channel message received"
#define GROWL_MSG_CHANNEL_NOTICE			@"Channel notice received"
#define GROWL_MSG_TALK_MSG					@"Talk message received"
#define GROWL_MSG_TALK_NOTICE				@"Talk notice received"
#define GROWL_MSG_KICKED					@"Kicked out from channel"
#define GROWL_MSG_INVITED					@"Invited to channel"
#define GROWL_MSG_FILE_RECEIVE_REQUEST		@"File receive requested"
#define GROWL_MSG_FILE_RECEIVE_SUCCEEDED	@"File receive succeeded"
#define GROWL_MSG_FILE_RECEIVE_FAILED		@"File receive failed"
#define GROWL_MSG_FILE_SEND_SUCCEEDED		@"File send succeeded"
#define GROWL_NSG_FILE_SEND_FAILED			@"File send failed"

#define CLICK_INTERVAL						2


@implementation GrowlController

@synthesize owner;

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

- (void)notify:(GrowlNotificationType)type title:(NSString*)title desc:(NSString*)desc context:(id)context
{
	if (![Preferences growlEnabledForEvent:type]) return;
	
	int priority = 0;
	BOOL sticky = [Preferences growlStickyForEvent:type];
	NSString* kind = nil;
	
	switch (type) {
		case GROWL_HIGHLIGHT:
			kind = GROWL_MSG_HIGHLIGHT;
			priority = 1;
			title = [NSString stringWithFormat:@"Highlight: %@", title];
			break;
		case GROWL_NEW_TALK:
			kind = GROWL_MSG_NEW_TALK;
			priority = 1;
			title = @"New Talk";
			//title = [NSString stringWithFormat:@"New Talk: %@", title];
			break;
		case GROWL_CHANNEL_MSG:
			kind = GROWL_MSG_CHANNEL_MSG;
			break;
		case GROWL_CHANNEL_NOTICE:
			kind = GROWL_MSG_CHANNEL_NOTICE;
			title = [NSString stringWithFormat:@"Notice: %@", title];
			break;
		case GROWL_TALK_MSG:
			kind = GROWL_MSG_TALK_MSG;
			title = @"Talk";
			//title = [NSString stringWithFormat:@"Talk: %@", title];
			break;
		case GROWL_TALK_NOTICE:
			kind = GROWL_MSG_TALK_NOTICE;
			title = @"Talk Notice";
			//title = [NSString stringWithFormat:@"Talk Notice: %@", title];
			break;
		case GROWL_KICKED:
			kind = GROWL_MSG_KICKED;
			title = [NSString stringWithFormat:@"Kicked: %@", title];
			break;
		case GROWL_INVITED:
			kind = GROWL_MSG_INVITED;
			title = [NSString stringWithFormat:@"Invited: %@", title];
			break;
		case GROWL_LOGIN:
			kind = GROWL_MSG_LOGIN;
			title = [NSString stringWithFormat:@"Logged in: %@", title];
			break;
		case GROWL_DISCONNECT:
			kind = GROWL_MSG_DISCONNECT;
			title = [NSString stringWithFormat:@"Disconnected: %@", title];
			break;
		case GROWL_FILE_RECEIVE_REQUEST:
			kind = GROWL_MSG_FILE_RECEIVE_REQUEST;
			desc = [NSString stringWithFormat:@"From %@\n%@", title, desc];
			title = @"File receive request";
			context = @"dcc";
			break;
		case GROWL_FILE_RECEIVE_SUCCESS:
			kind = GROWL_MSG_FILE_RECEIVE_SUCCEEDED;
			desc = [NSString stringWithFormat:@"From %@\n%@", title, desc];
			title = @"File receive succeeded";
			context = @"dcc";
			break;
		case GROWL_FILE_RECEIVE_ERROR:
			kind = GROWL_MSG_FILE_RECEIVE_FAILED;
			desc = [NSString stringWithFormat:@"From %@\n%@", title, desc];
			title = @"File receive failed";
			context = @"dcc";
			break;
		case GROWL_FILE_SEND_SUCCESS:
			kind = GROWL_MSG_FILE_SEND_SUCCEEDED;
			desc = [NSString stringWithFormat:@"To %@\n%@", title, desc];
			title = @"File send succeeded";
			context = @"dcc";
			break;
		case GROWL_FILE_SEND_ERROR:
			kind = GROWL_NSG_FILE_SEND_FAILED;
			desc = [NSString stringWithFormat:@"To %@\n%@", title, desc];
			title = @"File send failed";
			context = @"dcc";
			break;
		default:
			break;
	}
	
	
	[GrowlApplicationBridge notifyWithTitle:title
								description:desc
						   notificationName:kind
								   iconData:nil
								   priority:priority
								   isSticky:sticky
							   clickContext:context];
}

- (NSDictionary*)registrationDictionaryForGrowl
{
	NSMutableDictionary* dic = [NSMutableDictionary dictionary];
	NSArray* all = [NSArray arrayWithObjects:
					GROWL_MSG_LOGIN, GROWL_MSG_DISCONNECT, GROWL_MSG_HIGHLIGHT,
					GROWL_MSG_NEW_TALK, GROWL_MSG_CHANNEL_MSG, GROWL_MSG_CHANNEL_NOTICE,
					GROWL_MSG_TALK_MSG, GROWL_MSG_TALK_NOTICE, GROWL_MSG_KICKED, 
					GROWL_MSG_INVITED, GROWL_MSG_FILE_RECEIVE_REQUEST, GROWL_MSG_FILE_RECEIVE_SUCCEEDED,
					GROWL_MSG_FILE_RECEIVE_FAILED, GROWL_MSG_FILE_SEND_SUCCEEDED, GROWL_NSG_FILE_SEND_FAILED,
					nil];
	[dic setObject:all forKey:GROWL_NOTIFICATIONS_ALL];
	[dic setObject:all forKey:GROWL_NOTIFICATIONS_DEFAULT];
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
	
	[owner.window makeKeyAndOrderFront:nil];
	[NSApp activateIgnoringOtherApps:YES];
	
	if ([context isEqualToString:@"dcc"]) {
		[owner.dcc show:YES];
	}
	else if ([context isKindOfClass:[NSString class]]) {
		NSString* s = context;
		NSArray* ary = [s componentsSeparatedByString:@" "];
		if (ary.count >= 2) {
			int uid = [[ary objectAtIndex:0] intValue];
			int cid = [[ary objectAtIndex:1] intValue];
			
			IRCClient* u = [owner findClientById:uid];
			IRCChannel* c = [owner findChannelByClientId:uid channelId:cid];
			if (c) {
				[owner select:c];
			}
			else if (u) {
				[owner select:u];
			}
		}
		else if (ary.count == 1) {
			int uid = [[ary objectAtIndex:0] intValue];
			
			IRCClient* u = [owner findClientById:uid];
			if (u) {
				[owner select:u];
			}
		}
	}
}

@end
