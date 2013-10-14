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

@property (nonatomic, readonly) LogView* view;
@property (nonatomic, weak) IRCWorld* world;
@property (nonatomic, weak) IRCClient* client;
@property (nonatomic, weak) IRCChannel* channel;
@property (nonatomic) NSMenu* menu;
@property (nonatomic) NSMenu* urlMenu;
@property (nonatomic) NSMenu* addrMenu;
@property (nonatomic) NSMenu* chanMenu;
@property (nonatomic) NSMenu* memberMenu;
@property (nonatomic) ViewTheme* theme;
@property (nonatomic) BOOL console;
@property (nonatomic) NSColor* initialBackgroundColor;
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
