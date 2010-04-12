// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "NSColorHelper.h"
#import "Regex.h"


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
		static Regex* rgba = nil;
		if (!rgba) {
			rgba = [[Regex alloc] initWithStringNoCase:@"^rgba\\( *(\\d+) *, *(\\d+) *, *(\\d+) *, *(\\d*(?:\\.\\d+)) *\\)$"];
		}
		
		if ([rgba match:s].location != NSNotFound) {
			int r = [[s substringWithRange:[rgba groupAt:1]] intValue];
			int g = [[s substringWithRange:[rgba groupAt:2]] intValue];
			int b = [[s substringWithRange:[rgba groupAt:3]] intValue];
			float a = [[s substringWithRange:[rgba groupAt:4]] floatValue];
			[rgba reset];
			return DEVICE_RGBA(r, g, b, a);
		}
		
		static Regex* rgb = nil;
		if (!rgb) {
			rgb = [[Regex alloc] initWithStringNoCase:@"^rgb\\( *(\\d+) *, *(\\d+) *, *(\\d+) *\\)$"];
		}
		
		if ([rgb match:s].location != NSNotFound) {
			int r = [[s substringWithRange:[rgb groupAt:1]] intValue];
			int g = [[s substringWithRange:[rgb groupAt:2]] intValue];
			int b = [[s substringWithRange:[rgb groupAt:3]] intValue];
			[rgb reset];
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
