// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "OtherTheme.h"
#import "YAML.h"
#import "NSColorHelper.h"


@interface OtherTheme (Private)
- (NSString*)loadString:(NSString*)key, ...;
- (NSColor*)loadColor:(NSString*)key, ...;
@end


@implementation OtherTheme

@synthesize fileName;

- (id)init
{
	if (self = [super init]) {
	}
	return self;
}

- (void)dealloc
{
	[fileName release];
	[content release];
	
	[logNickFormat release];
	[logScrollerMarkColor release];
	[inputTextBgColor release];
	
	[super dealloc];
}

- (void)setFileName:(NSString *)value
{
	if (fileName != value) {
		[fileName release];
		fileName = [value retain];
		
		[self reload];
	}
}

- (void)reload
{
	[content release];
	content = nil;
	
	[logNickFormat release];
	logNickFormat = nil;
	
	[logScrollerMarkColor release];
	logScrollerMarkColor = nil;
	
	[inputTextBgColor release];
	inputTextBgColor = nil;
	
	if (!fileName) return;
	
	NSData* data = [NSData dataWithContentsOfFile:fileName];
	NSDictionary* dic = yaml_parse_raw_utf8(data.bytes, data.length);
	
	if (![dic isKindOfClass:[NSDictionary class]]) return;
	
	content = [dic retain];
	
	logNickFormat = [self loadString:@"log-view", @"nickname-format", nil] ?: @"%n: ";
	[logNickFormat retain];
	
	logScrollerMarkColor = [self loadColor:@"input-text", @"background-color"] ?: [NSColor magentaColor];
	[logScrollerMarkColor retain];
	
	inputTextBgColor = [self loadColor:@"input-text", @"background-color"] ?: [NSColor whiteColor];
	[inputTextBgColor retain];
}

- (NSString*)loadString:(NSString*)key, ...
{
	va_list args;
	va_start(args, key);
	
	NSDictionary* dic = [content objectForKey:key];
	while ([dic isKindOfClass:[NSDictionary class]] && (key = va_arg(args, id))) {
		dic = [dic objectForKey:key];
	}
	
	va_end(args);
	
	return (NSString*)dic;
}

- (NSColor*)loadColor:(NSString*)key, ...
{
	va_list args;
	va_start(args, key);
	
	NSDictionary* dic = [content objectForKey:key];
	while ([dic isKindOfClass:[NSDictionary class]] && (key = va_arg(args, id))) {
		dic = [dic objectForKey:key];
	}
	
	va_end(args);
	
	NSString* s = (NSString*)dic;
	return [NSColor fromCSS:s];
}

@end
