// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "IgnoreItem.h"
#import "NSDictionaryHelper.h"
#import "NSStringHelper.h"


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
	[nickRegex release];
	[textRegex release];
	[super dealloc];
}

- (id)init
{
	self = [super init];
	if (self) {
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

- (BOOL)isEqual:(id)other
{
	if (![other isKindOfClass:[IgnoreItem class]]) {
		return NO;
	}
	
	IgnoreItem* g = (IgnoreItem*)other;
	
	if (useRegexForNick != g.useRegexForNick) {
		return NO;
	}
	
	if (useRegexForText != g.useRegexForText) {
		return NO;
	}
	
	if (nick && g.nick && ![nick isEqualNoCase:g.nick]) {
		return NO;
	}
	
	if (text && g.text && ![text isEqualNoCase:g.text]) {
		return NO;
	}
	
	if ((!channels || !channels.count) && (!g.channels || !g.channels.count)) {
		;
	}
	else {
		if (![channels isEqualToArray:g.channels]) {
			return NO;
		}
	}
	
	return YES;
}

- (void)setNick:(NSString *)value
{
	if (![nick isEqualToString:value]) {
		[nick release];
		nick = [value retain];
		
		[nickRegex release];
		nickRegex = nil;
	}
}

- (void)setText:(NSString *)value
{
	if (![text isEqualToString:value]) {
		[text release];
		text = [value retain];
		
		[textRegex release];
		textRegex = nil;
	}
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

- (BOOL)checkIgnore:(NSString*)inputText nick:(NSString*)inputNick channel:(NSString*)channel
{
	// check nick
	if (!inputNick && nick.length) {
		return NO;
	}
	
	if (inputNick.length > 0 && nick.length > 0) {
		if (useRegexForNick) {
			if (!nickRegex) {
				nickRegex = [[OnigRegexp compileIgnorecase:nick] retain];
			}
			
			if (nickRegex) {
				OnigResult* result = [nickRegex search:inputNick];
				if (!result) {
					return NO;
				}
			}
		}
		else {
			if (![inputNick isEqualNoCase:nick]) {
				return NO;
			}
		}
	}
	
	// check text
	if (!inputText && text.length) {
		return NO;
	}
	
	if (inputText && text.length > 0) {
		if (useRegexForText) {
			if (!textRegex) {
				textRegex = [[OnigRegexp compileIgnorecase:text] retain];
			}
			
			if (textRegex) {
				OnigResult* result = [textRegex search:inputText];
				if (!result) {
					return NO;
				}
			}
		}
		else {
			NSRange range = [inputText rangeOfString:text options:NSCaseInsensitiveSearch];
			if (range.location == NSNotFound) {
				return NO;
			}
		}
	}
	
	// check channels
	if (!channel && channels.count) {
		return NO;
	}
	
	if (channel && channels.count) {
		BOOL matched = NO;
		for (NSString* s in channels) {
			if (![s isChannelName]) {
				s = [@"#" stringByAppendingString:s];
			}
			if ([channel isEqualNoCase:s]) {
				matched = YES;
				break;
			}
		}
		
		if (!matched) {
			return NO;
		}
	}
	
	return YES;
}

@end
