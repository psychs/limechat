// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "OtherTheme.h"
#import "YAML.h"
#import "NSColorHelper.h"


@interface OtherTheme (Private)
- (NSString*)loadString:(NSString*)key, ...;
- (NSColor*)loadColor:(NSString*)key, ...;
- (NSFont*)loadFont:(NSString*)key;
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
	
	[inputTextFont release];
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
	
	[inputTextFont release];
	inputTextFont = nil;
	
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
	
	inputTextFont = [self loadFont:@"input-text"] ?: [NSFont systemFontOfSize:0];
	[inputTextFont retain];
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

- (NSFont*)loadFont:(NSString*)key
{
	NSDictionary* dic = [content objectForKey:key];
	
	if (![dic isKindOfClass:[NSDictionary class]]) return nil;
	
	NSString* family = [dic objectForKey:@"font-family"];
	NSNumber* sizeNum = [dic objectForKey:@"font-size"];
	NSString* weight = [dic objectForKey:@"font-weight"];
	NSString* style = [dic objectForKey:@"font-style"];
	
	CGFloat size = 0;
	if (sizeNum) {
		size = [sizeNum floatValue];
	}
	else {
		size = [NSFont systemFontSize];
	}
	
	NSFont* font = nil;
	if (family) {
		font = [NSFont fontWithName:family size:size];
	}
	else {
		font = [NSFont systemFontOfSize:size];
	}
	
	if (!font) {
		font = [NSFont systemFontOfSize:0];
	}
	
	NSFontManager* fm = [NSFontManager sharedFontManager];
	if ([weight isEqualToString:@"bold"]) {
		NSFont* to = [fm convertFont:font toHaveTrait:NSBoldFontMask];
		if (to) {
			font = to;
		}
	}
	
	if ([style isEqualToString:@"italic"]) {
		NSFont* to = [fm convertFont:font toHaveTrait:NSItalicFontMask];
		if (to) {
			font = to;
		}
	}
	
	return font;
}

@end
