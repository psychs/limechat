// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "LogScriptEventSink.h"
#import "GTMNSString+HTML.h"
#import "LogController.h"
#import "LogPolicy.h"


#define DOUBLE_CLICK_RADIUS	3


@implementation LogScriptEventSink

@synthesize owner;
@synthesize policy;

- (id)init
{
	if (self = [super init]) {
		x = -10000;
		y = -10000;
	}
	return self;
}

- (void)dealloc
{
	[policy release];
	[super dealloc];
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)sel
{
	if (sel == @selector(onDblClick:)
		|| sel == @selector(shouldStopDoubleClick:)
		|| sel == @selector(setUrl:)
		|| sel == @selector(setAddr:)
		|| sel == @selector(setNick:)
		|| sel == @selector(setChan:)
		|| sel == @selector(print:)) {
		return NO;
	}
	return YES;
}

+ (NSString*)webScriptNameForSelector:(SEL)sel
{
	NSString* s = NSStringFromSelector(sel);
	if ([s hasSuffix:@":"]) {
		return [s substringToIndex:s.length - 1];
	}
	return nil;
}

+ (BOOL)isKeyExcludedFromWebScript:(const char *)name
{
	return YES;
}

+ (NSString *)webScriptNameForKey:(const char *)name
{
	return nil;
}

- (void)onDblClick:(id)e
{
	[owner logViewOnDoubleClick:e];
}

- (BOOL)shouldStopDoubleClick:(id)e
{
	int d = DOUBLE_CLICK_RADIUS;
	int cx = [[e valueForKey:@"clientX"] intValue];
	int cy = [[e valueForKey:@"clientY"] intValue];
	
	BOOL res = NO;
	
	CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
	
	if (x-d <= cx && cx <= x+d && y-d <= cy && cy <= y+d) {
		if (now < lastClickTime + GetDblTime() / 60.0) {
			res = YES;
		}
	}
	
	lastClickTime = now;
	x = cx;
	y = cy;
	
	return res;
}

- (void)setUrl:(NSString*)s
{
	[policy setUrl:[s gtm_stringByUnescapingFromHTML]];
}

- (void)setAddr:(NSString*)s
{
	[policy setAddr:[s gtm_stringByUnescapingFromHTML]];
}

- (void)setNick:(NSString*)s
{
	[policy setNick:[s gtm_stringByUnescapingFromHTML]];
}

- (void)setChan:(NSString*)s
{
	[policy setChan:[s gtm_stringByUnescapingFromHTML]];
}

- (void)print:(NSString*)s
{
	NSLog(@"%@", s);
}

@end
