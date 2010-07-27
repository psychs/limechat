// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "URLOpener.h"
#import "Preferences.h"


@implementation URLOpener

+ (void)open:(NSURL*)url
{
	NSWorkspace* ws = [NSWorkspace sharedWorkspace];
	
	if ([Preferences openBrowserInBackground]) {
		[ws openURLs:[NSArray arrayWithObject:url] withAppBundleIdentifier:nil options:NSWorkspaceLaunchWithoutActivation additionalEventParamDescriptor:nil launchIdentifiers:nil];
	}
	else {
		[ws openURL:url];
	}
}

+ (void)openAndActivate:(NSURL*)url
{
	[[NSWorkspace sharedWorkspace] openURL:url];
}

@end
