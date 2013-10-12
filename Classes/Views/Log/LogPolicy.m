// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "LogPolicy.h"
#import <WebKit/WebKit.h>
#import "URLOpener.h"
#import "MenuController.h"


@implementation LogPolicy

- (id)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (NSUInteger)webView:(WebView*)sender dragDestinationActionMaskForDraggingInfo:(id)draggingInfo
{
    return WebDragDestinationActionNone;
}

- (NSArray *)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems
{
    if (_url) {
        _menuController.pointedUrl = _url;
        _url = nil;

        NSMutableArray* ary = [NSMutableArray array];
        for (NSMenuItem* item in [_urlMenu itemArray]) {
            [ary addObject:[item copy]];
        }
        return ary;
    }
    else if (_addr) {
        _menuController.pointedAddress = _addr;
        _addr = nil;

        NSMutableArray* ary = [NSMutableArray array];
        for (NSMenuItem* item in [_addrMenu itemArray]) {
            [ary addObject:[item copy]];
        }
        return ary;
    }
    else if (_nick) {
        NSMutableArray* ary = [NSMutableArray array];
        NSMenuItem* nickItem = [[NSMenuItem alloc] initWithTitle:_nick action:nil keyEquivalent:@""];
        [ary addObject:nickItem];
        [ary addObject:[NSMenuItem separatorItem]];

        _menuController.pointedNick = _nick;
        _nick = nil;

        for (NSMenuItem* originalItem in [_memberMenu itemArray]) {
            NSMenuItem* item = [originalItem copy];
            [self modifyMemberMenuItem:item];
            [ary addObject:item];
        }
        return ary;
    }
    else if (_chan) {
        _menuController.pointedChannelName = _chan;
        _chan = nil;

        NSMutableArray* ary = [NSMutableArray array];
        for (NSMenuItem* item in [_chanMenu itemArray]) {
            [ary addObject:[item copy]];
        }
        return ary;
    }
    else if (_menu){
        NSMutableArray* ary = [NSMutableArray array];
        for (NSMenuItem* item in [_menu itemArray]) {
            [ary addObject:[item copy]];
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
