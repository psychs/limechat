// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "IRCClientConfig.h"
#import "IRCChannelConfig.h"
#import "NSDictionaryHelper.h"


@implementation IRCClientConfig

@synthesize name;

@synthesize host;
@synthesize port;
@synthesize useSSL;

@synthesize nick;
@synthesize password;
@synthesize username;
@synthesize realName;
@synthesize nickPassword;
@synthesize altNicks;

@synthesize proxyType;
@synthesize proxyHost;
@synthesize proxyPort;
@synthesize proxyUser;
@synthesize proxyPassword;

@synthesize autoConnect;
@synthesize encoding;
@synthesize fallbackEncoding;
@synthesize leavingComment;
@synthesize userInfo;
@synthesize invisibleMode;
@synthesize loginCommands;
@synthesize channels;
@synthesize autoOp;

@synthesize uid;

- (id)initWithDictionary:(NSDictionary*)dic
{
	if (self = [super init]) {
		altNicks = [NSMutableArray new];
		loginCommands = [NSMutableArray new];
		autoOp = [NSMutableArray new];
		channels = [NSMutableArray new];
		
		name = [[dic stringForKey:@"name"] retain];
		
		host = [[dic stringForKey:@"host"] retain];
		port = [dic intForKey:@"port"];
		useSSL = [dic boolForKey:@"ssl"];
		
		nick = [[dic stringForKey:@"nick"] retain];
		password = [[dic stringForKey:@"password"] retain];
		username = [[dic stringForKey:@"username"] retain];
		nickPassword = [[dic stringForKey:@"nickPassword"] retain];
		[altNicks addObjectsFromArray:[dic arrayForKey:@"alt_nicks"]];

		proxyType = [dic intForKey:@"proxy"];
		proxyHost = [[dic stringForKey:@"proxy_host"] retain];
		proxyPort = [dic intForKey:@"proxy_port"];
		proxyUser = [[dic stringForKey:@"proxy_user"] retain];
		proxyPassword = [[dic stringForKey:@"proxy_password"] retain];

		autoConnect = [dic boolForKey:@"auto_connect"];
		encoding = [dic intForKey:@"encoding"];
		fallbackEncoding = [dic intForKey:@"fallback_encoding"];
		leavingComment = [[dic stringForKey:@"leaving_comment"] retain];
		userInfo = [[dic stringForKey:@"userinfo"] retain];
		invisibleMode = [dic boolForKey:@"invisible"];
		
		[loginCommands addObjectsFromArray:[dic arrayForKey:@"login_commands"]];
		
		for (NSDictionary* e in [dic arrayForKey:@"channels"]) {
			IRCChannelConfig* c = [[[IRCChannelConfig alloc] initWithDictionary:e] autorelease];
			[channels addObject:c];
		}
		
		[autoOp addObjectsFromArray:[dic arrayForKey:@"autoop"]];
	}
	return self;
}

- (void)dealloc
{
	[name release];
	
	[host release];
	
	[nick release];
	[password release];
	[username release];
	[realName release];
	[nickPassword release];
	[altNicks release];

	[proxyHost release];
	[proxyUser release];
	[proxyPassword release];
	
	[leavingComment release];
	[userInfo release];
	[loginCommands release];
	[channels release];
	[autoOp release];
	
	[super dealloc];
}

- (NSDictionary*)dictionaryValue
{
	NSMutableDictionary* dic = [NSMutableDictionary dictionary];
	
	[dic setObject:name forKey:@"name"];
	
	[dic setObject:host forKey:@"host"];
	[dic setInt:port forKey:@"port"];
	[dic setBool:useSSL forKey:@"ssl"];
	
	[dic setObject:nick forKey:@"nick"];
	[dic setObject:password forKey:@"password"];
	[dic setObject:username forKey:@"username"];
	[dic setObject:nickPassword forKey:@"nickPassword"];
	[dic setObject:altNicks forKey:@"alt_nicks"];
	
	[dic setInt:proxyType forKey:@"proxy"];
	[dic setObject:proxyHost forKey:@"proxy_host"];
	[dic setInt:proxyPort forKey:@"proxy_port"];
	[dic setObject:proxyUser forKey:@"proxy_user"];
	[dic setObject:proxyPassword forKey:@"proxy_password"];
	
	[dic setBool:autoConnect forKey:@"auto_connect"];
	[dic setInt:encoding forKey:@"encoding"];
	[dic setInt:fallbackEncoding forKey:@"fallback_encoding"];
	[dic setObject:leavingComment forKey:@"leaving_comment"];
	[dic setObject:userInfo forKey:@"userinfo"];
	[dic setBool:invisibleMode forKey:@"invisible"];
	
	[dic setObject:loginCommands forKey:@"login_commands"];
	
	NSMutableArray* channelAry = [NSMutableArray array];
	for (IRCChannelConfig* e in channels) {
		[channelAry addObject:[e dictionaryValue]];
	}
	[dic setObject:channelAry forKey:@"channels"];
	
	[dic setObject:autoOp forKey:@"autoop"];
	
	return dic;
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
	return [[IRCClientConfig allocWithZone:zone] initWithDictionary:[self dictionaryValue]];
}

@end
