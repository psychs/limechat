// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "IRCChannelConfig.h"
#import "NSDictionaryHelper.h"


@implementation IRCChannelConfig

@synthesize type;

@synthesize name;
@synthesize password;

@synthesize autoJoin;
@synthesize logToConsole;
@synthesize growl;

@synthesize mode;
@synthesize topic;

@synthesize autoOp;

- (id)init
{
	if (self = [super init]) {
		type = CHANNEL_TYPE_CHANNEL;
		autoOp = [NSMutableArray new];
		
		autoJoin = YES;
		logToConsole = YES;
		growl = YES;
		
		name = @"";
		password = @"";
		mode = @"+sn";
		topic = @"";
	}
	return self;
}

- (id)initWithDictionary:(NSDictionary*)dic
{
	[self init];
	
	type = [dic intForKey:@"type"];
	
	name = [[dic stringForKey:@"name"] retain] ?: @"";
	password = [[dic stringForKey:@"password"] retain] ?: @"";
	
	autoJoin = [dic boolForKey:@"auto_join"];
	logToConsole = [dic boolForKey:@"console"];
	growl = [dic boolForKey:@"growl"];

	mode = [[dic stringForKey:@"mode"] retain] ?: @"";
	topic = [[dic stringForKey:@"topic"] retain] ?: @"";

	[autoOp addObjectsFromArray:[dic arrayForKey:@"autoop"]];
	
	return self;
}

- (void)dealloc
{
	[name release];
	[password release];
	
	[mode release];
	[topic release];
	
	[autoOp release];
	
	[super dealloc];
}

- (NSMutableDictionary*)dictionaryValue
{
	NSMutableDictionary* dic = [NSMutableDictionary dictionary];
	
	[dic setInt:type forKey:@"type"];
	
	if (name) [dic setObject:name forKey:@"name"];
	if (password) [dic setObject:password forKey:@"password"];
	
	[dic setBool:autoJoin forKey:@"auto_join"];
	[dic setBool:logToConsole forKey:@"console"];
	[dic setBool:growl forKey:@"growl"];
	
	if (mode) [dic setObject:mode forKey:@"mode"];
	if (topic) [dic setObject:topic forKey:@"topic"];
	
	if (autoOp) [dic setObject:autoOp forKey:@"autoop"];
	
	return dic;
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
	return [[IRCChannelConfig allocWithZone:zone] initWithDictionary:[self dictionaryValue]];
}

@end
