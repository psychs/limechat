// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "NSColorHelper.h"
#import "OnigRegexp.h"


@implementation NSColor (NSColorHelper)

+ (NSColor*)fromCSS:(NSString*)s
{
	if ([s hasPrefix:@"#"]) {
		s = [s substringFromIndex:1];
		
		int len = s.length;
		if (len == 6) {
			long n = strtol([s UTF8String], NULL, 16);
			int r = (n >> 16) & 0xff;
			int g = (n >> 8) & 0xff;
			int b = n & 0xff;
			return DEVICE_RGB(r, g, b);
		}
		else if (len == 3) {
			long n = strtol([s UTF8String], NULL, 16);
			int r = (n >> 8) & 0xf;
			int g = (n >> 4) & 0xf;
			int b = n & 0xf;
			return [NSColor colorWithDeviceRed:r/15.0 green:g/15.0 blue:b/15.0 alpha:1];
		}
	}
	else {
		static OnigRegexp* rgba = nil;
		if (!rgba) {
			NSString* pattern = @"rgba\\(\\s*(\\d+)\\s*,\\s*(\\d+)\\s*,\\s*(\\d+)\\s*,\\s*(\\d*(?:\\.\\d+))\\s*\\)";
			rgba = [[OnigRegexp compile:pattern] retain];
		}
		
		OnigResult* result = [rgba match:s];
		if (result) {
			int r = [[s substringWithRange:[result rangeAt:1]] intValue];
			int g = [[s substringWithRange:[result rangeAt:2]] intValue];
			int b = [[s substringWithRange:[result rangeAt:3]] intValue];
			float a = [[s substringWithRange:[result rangeAt:4]] floatValue];
			return DEVICE_RGBA(r, g, b, a);
		}
		
		static OnigRegexp* rgb = nil;
		if (!rgb) {
			NSString* pattern = @"rgb\\(\\s*(\\d+)\\s*,\\s*(\\d+)\\s*,\\s*(\\d+)\\s*\\)";
			rgb = [[OnigRegexp compile:pattern] retain];
		}
		
		result = [rgb match:s];
		if (result) {
			int r = [[s substringWithRange:[result rangeAt:1]] intValue];
			int g = [[s substringWithRange:[result rangeAt:2]] intValue];
			int b = [[s substringWithRange:[result rangeAt:3]] intValue];
			return DEVICE_RGB(r, g, b);
		}
	}
	
	static NSDictionary* nameMap = nil;
	if (!nameMap) {
		nameMap = [[NSDictionary dictionaryWithObjectsAndKeys:
				   DEVICE_RGB(0, 0, 0), @"black",
				   DEVICE_RGB(0xC0, 0xC0, 0xC0), @"silver",
				   DEVICE_RGB(0x80, 0x80, 0x80), @"gray",
				   DEVICE_RGB(0xFF, 0xFF, 0xFF), @"white",
				   DEVICE_RGB(0x80, 0, 0), @"maroon",
				   DEVICE_RGB(0xFF, 0, 0), @"red",
				   DEVICE_RGB(0x80, 0, 0x80), @"purple",
				   DEVICE_RGB(0xFF, 0, 0xFF), @"fuchsia",
				   DEVICE_RGB(0, 0x80, 0), @"green",
				   DEVICE_RGB(0, 0xFF, 0), @"lime",
				   DEVICE_RGB(0x80, 0x80, 0), @"olive",
				   DEVICE_RGB(0xFF, 0xFF, 0), @"yellow",
				   DEVICE_RGB(0, 0, 0x80), @"navy",
				   DEVICE_RGB(0, 0, 0xFF), @"blue",
				   DEVICE_RGB(0, 0x80, 0x80), @"teal",
				   DEVICE_RGB(0, 0xFF, 0xFF), @"aqua",
				   DEVICE_RGBA(0, 0, 0, 0), @"transparent",
				   nil] retain];
	}
	
	return [nameMap objectForKey:[s lowercaseString]];
}

@end
