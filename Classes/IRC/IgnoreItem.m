// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the new BSD license.

#import "IgnoreItem.h"
#import "NSDictionaryHelper.h"


@implementation IgnoreItem

@synthesize nick;
@synthesize text;
@synthesize useRegexForNick;
@synthesize useRegexForText;
@synthesize channels;

- (void)dealloc
{
	[nick release];
	[text release];
	[channels release];
	[super dealloc];
}

- (id)init
{
	if (self = [super init]) {
	}
	return self;
}

- (id)initWithDictionary:(NSDictionary*)dic
{
	if ([self init]) {
		nick = [[dic objectForKey:@"nick"] retain];
		text = [[dic objectForKey:@"text"] retain];
		useRegexForNick = [dic boolForKey:@"useRegexForNick"];
		useRegexForText = [dic boolForKey:@"useRegexForText"];
		channels = [[dic objectForKey:@"channels"] retain];
	}
	return self;
}

- (NSDictionary*)dictionaryValue
{
	NSMutableDictionary* dic = [NSMutableDictionary dictionary];
	
	if (nick) [dic setObject:nick forKey:@"nick"];
	if (text) [dic setObject:text forKey:@"text"];
	
	[dic setBool:useRegexForNick forKey:@"useRegexForNick"];
	[dic setBool:useRegexForText forKey:@"useRegexForText"];
	
	if (channels) [dic setObject:channels forKey:@"channels"];
	
	return dic;
}

- (BOOL)isValid
{
	return nick.length > 0 || text.length > 0;
}

- (NSString*)displayNick
{
	if (!nick || !nick.length) return @"";
	if (!useRegexForNick) return nick;
	return [NSString stringWithFormat:@"/%@/", nick];
}

- (NSString*)displayText
{
	if (!text || !text.length) return @"";
	if (!useRegexForText) return text;
	return [NSString stringWithFormat:@"/%@/", text];
}

@end
