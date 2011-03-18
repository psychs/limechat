// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "IRCWorldConfig.h"
#import "IRCClientConfig.h"
#import "NSDictionaryHelper.h"


@implementation IRCWorldConfig

@synthesize clients;
@synthesize autoOp;

- (id)init
{
	self = [super init];
	if (self) {
		clients = [NSMutableArray new];
		autoOp = [NSMutableArray new];
	}
	return self;
}

- (id)initWithDictionary:(NSDictionary*)dic
{
	[self init];
	
	NSArray* ary = [dic arrayForKey:@"clients"] ?: [dic arrayForKey:@"units"];
	
	for (NSDictionary* e in ary) {
		IRCClientConfig* c = [[[IRCClientConfig alloc] initWithDictionary:e] autorelease];
		[clients addObject:c];
	}
	
	[autoOp addObjectsFromArray:[dic arrayForKey:@"autoop"]];
	
	return self;
}

- (void)dealloc
{
	[clients release];
	[autoOp release];
	[super dealloc];
}

- (NSMutableDictionary*)dictionaryValue
{
	NSMutableDictionary* dic = [NSMutableDictionary dictionary];
	
	NSMutableArray* clientAry = [NSMutableArray array];
	for (IRCClientConfig* e in clients) {
		[clientAry addObject:[e dictionaryValue]];
	}
	[dic setObject:clientAry forKey:@"clients"];
	
	[dic setObject:autoOp forKey:@"autoop"];
	
	return dic;
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
	return [[IRCWorldConfig allocWithZone:zone] initWithDictionary:[self dictionaryValue]];
}

@end
