// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Cocoa/Cocoa.h>


@class IRCClient;
@class LogController;


@interface IRCTreeItem : NSObject <NSTableViewDataSource, NSTableViewDelegate>

@property (nonatomic) int uid;
@property (nonatomic) LogController* log;
@property (nonatomic) BOOL isKeyword;
@property (nonatomic) BOOL isUnread;
@property (nonatomic) BOOL isNewTalk;
@property (nonatomic) BOOL isActive;
@property (nonatomic, readonly) BOOL isClient;
@property (nonatomic, readonly) IRCClient* client;
@property (nonatomic, readonly) NSString* label;
@property (nonatomic, readonly) NSString* name;

- (void)resetState;
- (int)numberOfChildren;
- (IRCTreeItem*)childAtIndex:(int)index;

@end
