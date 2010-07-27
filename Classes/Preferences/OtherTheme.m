// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

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

@synthesize logNickFormat;
@synthesize logScrollerMarkColor;

@synthesize inputTextFont;
@synthesize inputTextBgColor;
@synthesize inputTextColor;
@synthesize inputTextSelColor;

@synthesize treeFont;
@synthesize treeBgColor;
@synthesize treeHighlightColor;
@synthesize treeNewTalkColor;
@synthesize treeUnreadColor;

@synthesize treeActiveColor;
@synthesize treeInactiveColor;

@synthesize treeSelActiveColor;
@synthesize treeSelInactiveColor;
@synthesize treeSelTopLineColor;
@synthesize treeSelBottomLineColor;
@synthesize treeSelTopColor;
@synthesize treeSelBottomColor;

@synthesize memberListFont;
@synthesize memberListBgColor;
@synthesize memberListColor;
@synthesize memberListOpColor;

@synthesize memberListSelColor;
@synthesize memberListSelTopLineColor;
@synthesize memberListSelBottomLineColor;
@synthesize memberListSelTopColor;
@synthesize memberListSelBottomColor;

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
	[inputTextColor release];
	[inputTextSelColor release];

	[treeFont release];
	[treeBgColor release];
	[treeHighlightColor release];
	[treeNewTalkColor release];
	[treeUnreadColor release];
	
	[treeActiveColor release];
	[treeInactiveColor release];
	
	[treeSelActiveColor release];
	[treeSelInactiveColor release];
	[treeSelTopLineColor release];
	[treeSelBottomLineColor release];
	[treeSelTopColor release];
	[treeSelBottomColor release];
	
	[memberListFont release];
	[memberListBgColor release];
	[memberListColor release];
	[memberListOpColor release];

	[memberListSelColor release];
	[memberListSelTopLineColor release];
	[memberListSelBottomLineColor release];
	[memberListSelTopColor release];
	[memberListSelBottomColor release];
	
	[super dealloc];
}

- (void)setFileName:(NSString *)value
{
	if (fileName != value) {
		[fileName release];
		fileName = [value retain];
	}
	
	[self reload];
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
	[inputTextColor release];
	inputTextColor = nil;
	[inputTextSelColor release];
	inputTextSelColor = nil;
	
	[treeFont release];
	treeFont = nil;
	[treeBgColor release];
	treeBgColor = nil;
	[treeHighlightColor release];
	treeHighlightColor = nil;
	[treeNewTalkColor release];
	treeNewTalkColor = nil;
	[treeUnreadColor release];
	treeUnreadColor = nil;
	
	[treeActiveColor release];
	treeActiveColor = nil;
	[treeInactiveColor release];
	treeInactiveColor = nil;
	
	[treeSelActiveColor release];
	treeSelActiveColor = nil;
	[treeSelInactiveColor release];
	treeSelInactiveColor = nil;
	[treeSelTopLineColor release];
	treeSelTopLineColor = nil;
	[treeSelBottomLineColor release];
	treeSelBottomLineColor = nil;
	[treeSelTopColor release];
	treeSelTopColor = nil;
	[treeSelBottomColor release];
	treeSelBottomColor = nil;
	
	[memberListFont release];
	memberListFont = nil;
	[memberListBgColor release];
	memberListBgColor = nil;
	[memberListColor release];
	memberListColor = nil;
	[memberListOpColor release];
	memberListOpColor = nil;
	
	[memberListSelColor release];
	memberListSelColor = nil;
	[memberListSelTopLineColor release];
	memberListSelTopLineColor = nil;
	[memberListSelBottomLineColor release];
	memberListSelBottomLineColor = nil;
	[memberListSelTopColor release];
	memberListSelTopColor = nil;
	[memberListSelBottomColor release];
	memberListSelBottomColor = nil;
	
	
	//if (!fileName) return;
	
	NSData* data = [NSData dataWithContentsOfFile:fileName];
	NSDictionary* dic = yaml_parse_raw_utf8(data.bytes, data.length);
	
	//if (![dic isKindOfClass:[NSDictionary class]]) return;
	
	content = [dic retain];
	
	logNickFormat = [self loadString:@"log-view", @"nickname-format", nil] ?: @"%n: ";
	[logNickFormat retain];
	
	logScrollerMarkColor = [self loadColor:@"log-view", @"scroller-highlight-color", nil] ?: [NSColor magentaColor];
	[logScrollerMarkColor retain];
	
	
	inputTextFont = [self loadFont:@"input-text"] ?: [NSFont systemFontOfSize:0];
	[inputTextFont retain];
	
	inputTextBgColor = [self loadColor:@"input-text", @"background-color", nil] ?: [NSColor whiteColor];
	[inputTextBgColor retain];
	
	inputTextColor = [self loadColor:@"input-text", @"color", nil] ?: [NSColor blackColor];
	[inputTextColor retain];
	
	inputTextSelColor = [self loadColor:@"input-text", @"selected", @"background-color", nil] ?: [NSColor selectedTextBackgroundColor];
	[inputTextSelColor retain];


	treeFont = [self loadFont:@"server-tree"] ?: [NSFont systemFontOfSize:0];
	[treeFont retain];
	
	treeBgColor = [self loadColor:@"server-tree", @"background-color", nil] ?: DEVICE_RGB(229, 237, 247);
	[treeBgColor retain];
	
	treeHighlightColor = [self loadColor:@"server-tree", @"highlight", @"color", nil] ?: [NSColor magentaColor];
	[treeHighlightColor retain];
	
	treeNewTalkColor = [self loadColor:@"server-tree", @"newtalk", @"color", nil] ?: [NSColor redColor];
	[treeNewTalkColor retain];
	
	treeUnreadColor = [self loadColor:@"server-tree", @"unread", @"color", nil] ?: [NSColor blueColor];
	[treeUnreadColor retain];

	
	treeActiveColor = [self loadColor:@"server-tree", @"normal", @"active", @"color", nil] ?: [NSColor blackColor];
	[treeActiveColor retain];
	
	treeInactiveColor = [self loadColor:@"server-tree", @"normal", @"inactive", @"color", nil] ?: [NSColor lightGrayColor];
	[treeInactiveColor retain];
	

	treeSelActiveColor = [self loadColor:@"server-tree", @"selected", @"active", @"color", nil] ?: [NSColor blackColor];
	[treeSelActiveColor retain];
	
	treeSelInactiveColor = [self loadColor:@"server-tree", @"selected", @"inactive", @"color", nil] ?: [NSColor grayColor];
	[treeSelInactiveColor retain];
	
	treeSelTopLineColor = [self loadColor:@"server-tree", @"selected", @"background", @"top-line-color", nil] ?: DEVICE_RGB(173, 187, 208);
	[treeSelTopLineColor retain];
	
	treeSelBottomLineColor = [self loadColor:@"server-tree", @"selected", @"background", @"bottom-line-color", nil] ?: DEVICE_RGB(140, 152, 176);
	[treeSelBottomLineColor retain];
	
	treeSelTopColor = [self loadColor:@"server-tree", @"selected", @"background", @"top-color", nil] ?: DEVICE_RGB(173, 187, 208);
	[treeSelTopColor retain];
	
	treeSelBottomColor = [self loadColor:@"server-tree", @"selected", @"background", @"bottom-color", nil] ?: DEVICE_RGB(152, 170, 196);
	[treeSelBottomColor retain];
	
	memberListFont = [self loadFont:@"member-list"] ?: [NSFont systemFontOfSize:[NSFont smallSystemFontSize]];
	[memberListFont retain];
	
	memberListBgColor = [self loadColor:@"member-list", @"background-color", nil] ?: [NSColor whiteColor];
	[memberListBgColor retain];
	
	memberListColor = [self loadColor:@"member-list", @"color", nil] ?: [NSColor blackColor];
	[memberListColor retain];
	
	memberListOpColor = [self loadColor:@"member-list", @"operator", @"color", nil] ?: [NSColor blackColor];
	[memberListOpColor retain];
	
	memberListSelColor = [self loadColor:@"member-list", @"selected", @"color", nil];
	[memberListSelColor retain];
	
	memberListSelTopLineColor = [self loadColor:@"member-list", @"selected", @"background", @"top-line-color", nil];
	[memberListSelTopLineColor retain];
	
	memberListSelBottomLineColor = [self loadColor:@"member-list", @"selected", @"background", @"bottom-line-color", nil];
	[memberListSelBottomLineColor retain];
	
	memberListSelTopColor = [self loadColor:@"member-list", @"selected", @"background", @"top-color", nil];
	[memberListSelTopColor retain];
	
	memberListSelBottomColor = [self loadColor:@"member-list", @"selected", @"background", @"bottom-color", nil];
	[memberListSelBottomColor retain];
	
	
	[content release];
	content = nil;
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
