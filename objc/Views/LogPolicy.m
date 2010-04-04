#import "LogPolicy.h"
#import <WebKit/WebKit.h>


@interface LogPolicy (Private)
- (void)modifyMemberMenu:(NSMenu*)menu;
- (void)modifyMemberMenuItem:(NSMenuItem*)item;
@end


@implementation LogPolicy

@synthesize owner;
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
		[[[owner world] menuController] setUrl:url];
		[url autorelease];
		url = nil;
		
		NSMutableArray* ary = [NSMutableArray array];
		for (NSMenuItem* item in [urlMenu itemArray]) {
			[ary addObject:[[item copy] autorelease]];
		}
		return ary;
	}
	else if (addr) {
		[[[owner world] menuController] setAddr:addr];
		[addr autorelease];
		addr = nil;
		
		NSMutableArray* ary = [NSMutableArray array];
		for (NSMenuItem* item in [addrMenu itemArray]) {
			[ary addObject:[[item copy] autorelease]];
		}
		return ary;
	}
	else if (nick) {
		[[[owner world] menuController] setNick:nick];
		
		NSMutableArray* ary = [NSMutableArray array];
		NSMenuItem* nickItem = [[[NSMenuItem alloc] initWithTitle:nick action:nil keyEquivalent:@""] autorelease];
		[ary addObject:nickItem];
		[ary addObject:[NSMenuItem separatorItem]];
		
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
		[[[owner world] menuController] setChan:chan];
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
			[[NSWorkspace sharedWorkspace] openURL:[actionInformation objectForKey:WebActionOriginalURLKey]];
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
