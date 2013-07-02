// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Cocoa/Cocoa.h>
#import "LogView.h"
#import "LogPolicy.h"
#import "LogScriptEventSink.h"
#import "LogLine.h"
#import "MarkedScroller.h"
#import "ViewTheme.h"
#import "WebViewAutoScroll.h"


@class IRCWorld;
@class IRCClient;
@class IRCChannel;


@interface LogController : NSObject
{
    LogView* view;
    LogPolicy* policy;
    LogScriptEventSink* sink;
    MarkedScroller* scroller;
    WebViewAutoScroll* autoScroller;

    __weak IRCWorld* world;
    __weak IRCClient* client;
    __weak IRCChannel* channel;
    NSMenu* menu;
    NSMenu* urlMenu;
    NSMenu* addrMenu;
    NSMenu* chanMenu;
    NSMenu* memberMenu;
    ViewTheme* theme;
    int maxLines;
    BOOL console;
    NSColor* initialBackgroundColor;

    BOOL becameVisible;
    BOOL bottom;
    BOOL movingToBottom;
    NSMutableArray* lines;
    int lineNumber;
    int count;
    BOOL needsLimitNumberOfLines;
    BOOL loaded;
    NSMutableArray* highlightedLineNumbers;
    int loadingImages;
    NSString* prevNickInfo;
    NSString* html;
    BOOL scrollBottom;
    int scrollTop;
    NSMutableSet *fetchingAvatarScreenNames;
}

@property (nonatomic, readonly) LogView* view;
@property (nonatomic, weak) IRCWorld* world;
@property (nonatomic, weak) IRCClient* client;
@property (nonatomic, weak) IRCChannel* channel;
@property (nonatomic, strong) NSMenu* menu;
@property (nonatomic, strong) NSMenu* urlMenu;
@property (nonatomic, strong) NSMenu* addrMenu;
@property (nonatomic, strong) NSMenu* chanMenu;
@property (nonatomic, strong) NSMenu* memberMenu;
@property (nonatomic, strong) ViewTheme* theme;
@property (nonatomic) BOOL console;
@property (nonatomic, strong) NSColor* initialBackgroundColor;
@property (nonatomic) int maxLines;
@property (nonatomic, readonly) BOOL viewingBottom;

- (void)setUp;
- (void)notifyDidBecomeVisible;

- (void)moveToTop;
- (void)moveToBottom;

- (void)mark;
- (void)unmark;
- (void)goToMark;
- (void)reloadTheme;
- (void)clear;
- (void)changeTextSize:(BOOL)bigger;
- (void)expandImage:(NSString*)url lineNumber:(int)aLineNumber imageIndex:(int)imageIndex contentLength:(long long)contentLength contentType:(NSString*)contentType;

- (BOOL)print:(LogLine*)line;

- (void)logViewOnDoubleClick:(NSString*)e;

@end
