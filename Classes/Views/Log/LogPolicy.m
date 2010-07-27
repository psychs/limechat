// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "LogPolicy.h"
#import <WebKit/WebKit.h>
#import "URLOpener.h"
#import "MenuController.h"


@interface LogPolicy (Private)
- (void)modifyMemberMenu:(NSMenu*)menu;
- (void)modifyMemberMenuItem:(NSMenuItem*)item;
@end


@implementation LogPolicy

@synthesize menuController;
@synthesize menu;
@synthesize urlMenu;
@synthesize addrMenu;
@synthesize memberMenu;
@synthesize chanMenu;
@synthesize url;
@synthesize addr;
@synthesize nick;
@synthesize chan;

- (id)init
{
	if (self = [super init]) {
	}
	return self;
}

- (void)dealloc
{
	[menu release];
	[urlMenu release];
	[addrMenu release];
	[memberMenu release];
	[chanMenu release];
	[url release];
	[addr release];
	[nick release];
	[chan release];
	[super dealloc];
}

- (NSUInteger)webView:(WebView*)sender dragDestinationActionMaskForDraggingInfo:(id)draggingInfo
{
	return WebDragDestinationActionNone;
}

- (NSArray *)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems
{
	if (url) {
		menuController.pointedUrl = url;
		[url autorelease];
		url = nil;
		
		NSMutableArray* ary = [NSMutableArray array];
		for (NSMenuItem* item in [urlMenu itemArray]) {
			[ary addObject:[[item copy] autorelease]];
		}
		return ary;
	}
	else if (addr) {
		menuController.pointedAddress = addr;
		[addr autorelease];
		addr = nil;
		
		NSMutableArray* ary = [NSMutableArray array];
		for (NSMenuItem* item in [addrMenu itemArray]) {
			[ary addObject:[[item copy] autorelease]];
		}
		return ary;
	}
	else if (nick) {
		NSMutableArray* ary = [NSMutableArray array];
		NSMenuItem* nickItem = [[[NSMenuItem alloc] initWithTitle:nick action:nil keyEquivalent:@""] autorelease];
		[ary addObject:nickItem];
		[ary addObject:[NSMenuItem separatorItem]];
		
		menuController.pointedNick = nick;
		[nick autorelease];
		nick = nil;
		
		for (NSMenuItem* item in [memberMenu itemArray]) {
			item = [[item copy] autorelease];
			[self modifyMemberMenuItem:item];
			[ary addObject:item];
		}
		return ary;
	}
	else if (chan) {
		menuController.pointedChannelName = chan;
		[chan autorelease];
		chan = nil;
		
		NSMutableArray* ary = [NSMutableArray array];
		for (NSMenuItem* item in [chanMenu itemArray]) {
			[ary addObject:[[item copy] autorelease]];
		}
		return ary;
	}
	else if (menu){
		NSMutableArray* ary = [NSMutableArray array];
		for (NSMenuItem* item in [menu itemArray]) {
			[ary addObject:[[item copy] autorelease]];
		}
		return ary;
	}
	else {
		return [NSArray array];
	}
}

- (void)modifyMemberMenu:(NSMenu*)submenu
{
	for (NSMenuItem* item in [submenu itemArray]) {
		[self modifyMemberMenuItem:item];
	}
}

- (void)modifyMemberMenuItem:(NSMenuItem*)item
{
	item.tag += 500;
	if ([item hasSubmenu]) [self modifyMemberMenu:item.submenu];
}

- (void)webView:(WebView *)webView decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id < WebPolicyDecisionListener >)listener
{
	int action = [[actionInformation objectForKey:WebActionNavigationTypeKey] intValue];
	switch (action) {
		case WebNavigationTypeLinkClicked:
			[listener ignore];
			[URLOpener open:[actionInformation objectForKey:WebActionOriginalURLKey]];
			break;
		case WebNavigationTypeOther:
			[listener use];
			break;
		default:
			[listener ignore];
			break;
	}
}

@end
