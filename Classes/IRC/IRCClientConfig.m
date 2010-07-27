// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "IRCClientConfig.h"
#import "IRCChannelConfig.h"
#import "IgnoreItem.h"
#import "NSDictionaryHelper.h"
#import "NSLocaleHelper.h"


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
@synthesize ignores;

@synthesize uid;

- (id)init
{
	if (self = [super init]) {
		altNicks = [NSMutableArray new];
		loginCommands = [NSMutableArray new];
		channels = [NSMutableArray new];
		autoOp = [NSMutableArray new];
		ignores = [NSMutableArray new];
		
		name = @"";
		host = @"";
		port = 6667;
		password = @"";
		nick = @"";
		username = @"";
		realName = @"";
		nickPassword = @"";
		
		proxyHost = @"";
		proxyPort = 1080;
		proxyUser = @"";
		proxyPassword = @"";
		
		encoding = NSUTF8StringEncoding;
		fallbackEncoding = NSISOLatin1StringEncoding;
		leavingComment = @"Leaving...";
		userInfo = @"";
		
		if ([NSLocale prefersJapaneseLanguage]) {
			encoding = NSISO2022JPStringEncoding;
		}
	}
	return self;
}

- (id)initWithDictionary:(NSDictionary*)dic
{
	[self init];
	
	name = [[dic stringForKey:@"name"] retain] ?: @"";
	
	host = [[dic stringForKey:@"host"] retain] ?: @"";
	port = [dic intForKey:@"port"] ?: 6667;
	password = [[dic stringForKey:@"password"] retain] ?: @"";
	useSSL = [dic boolForKey:@"ssl"];
	
	nick = [[dic stringForKey:@"nick"] retain] ?: @"";
	username = [[dic stringForKey:@"username"] retain] ?: @"";
	realName = [[dic stringForKey:@"realname"] retain] ?: @"";
	nickPassword = [[dic stringForKey:@"nickPassword"] retain] ?: @"";
	[altNicks addObjectsFromArray:[dic arrayForKey:@"alt_nicks"]];
	
	proxyType = [dic intForKey:@"proxy"];
	proxyHost = [[dic stringForKey:@"proxy_host"] retain] ?: @"";
	proxyPort = [dic intForKey:@"proxy_port"] ?: 1080;
	proxyUser = [[dic stringForKey:@"proxy_user"] retain] ?: @"";
	proxyPassword = [[dic stringForKey:@"proxy_password"] retain] ?: @"";

	autoConnect = [dic boolForKey:@"auto_connect"];
	encoding = [dic intForKey:@"encoding"] ?: NSUTF8StringEncoding;
	fallbackEncoding = [dic intForKey:@"fallback_encoding"] ?: NSISOLatin1StringEncoding;
	leavingComment = [[dic stringForKey:@"leaving_comment"] retain] ?: @"";
	userInfo = [[dic stringForKey:@"userinfo"] retain] ?: @"";
	invisibleMode = [dic boolForKey:@"invisible"];
	
	[loginCommands addObjectsFromArray:[dic arrayForKey:@"login_commands"]];
	
	for (NSDictionary* e in [dic arrayForKey:@"channels"]) {
		IRCChannelConfig* c = [[[IRCChannelConfig alloc] initWithDictionary:e] autorelease];
		[channels addObject:c];
	}
	
	[autoOp addObjectsFromArray:[dic arrayForKey:@"autoop"]];
	
	for (NSDictionary* e in [dic arrayForKey:@"ignores"]) {
		IgnoreItem* ignore = [[[IgnoreItem alloc] initWithDictionary:e] autorelease];
		[ignores addObject:ignore];
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
	[ignores release];
	
	[super dealloc];
}

- (NSMutableDictionary*)dictionaryValue
{
	NSMutableDictionary* dic = [NSMutableDictionary dictionary];
	
	if (name) [dic setObject:name forKey:@"name"];
	
	if (host) [dic setObject:host forKey:@"host"];
	[dic setInt:port forKey:@"port"];
	[dic setBool:useSSL forKey:@"ssl"];
	
	if (nick) [dic setObject:nick forKey:@"nick"];
	if (password) [dic setObject:password forKey:@"password"];
	if (username) [dic setObject:username forKey:@"username"];
	if (realName) [dic setObject:realName forKey:@"realname"];
	if (nickPassword) [dic setObject:nickPassword forKey:@"nickPassword"];
	if (altNicks) [dic setObject:altNicks forKey:@"alt_nicks"];
	
	[dic setInt:proxyType forKey:@"proxy"];
	if (proxyHost) [dic setObject:proxyHost forKey:@"proxy_host"];
	[dic setInt:proxyPort forKey:@"proxy_port"];
	if (proxyUser) [dic setObject:proxyUser forKey:@"proxy_user"];
	if (proxyPassword) [dic setObject:proxyPassword forKey:@"proxy_password"];
	
	[dic setBool:autoConnect forKey:@"auto_connect"];
	[dic setInt:encoding forKey:@"encoding"];
	[dic setInt:fallbackEncoding forKey:@"fallback_encoding"];
	if (leavingComment) [dic setObject:leavingComment forKey:@"leaving_comment"];
	if (userInfo) [dic setObject:userInfo forKey:@"userinfo"];
	[dic setBool:invisibleMode forKey:@"invisible"];
	
	if (altNicks) [dic setObject:loginCommands forKey:@"login_commands"];
	
	NSMutableArray* channelAry = [NSMutableArray array];
	for (IRCChannelConfig* e in channels) {
		[channelAry addObject:[e dictionaryValue]];
	}
	[dic setObject:channelAry forKey:@"channels"];
	
	[dic setObject:autoOp forKey:@"autoop"];
	
	NSMutableArray* ignoreAry = [NSMutableArray array];
	for (IgnoreItem* e in ignores) {
		if (e.isValid) {
			[ignoreAry addObject:[e dictionaryValue]];
		}
	}
	[dic setObject:ignoreAry forKey:@"ignores"];
	
	return dic;
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
	return [[IRCClientConfig allocWithZone:zone] initWithDictionary:[self dictionaryValue]];
}

@end
