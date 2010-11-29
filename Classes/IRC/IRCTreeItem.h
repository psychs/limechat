// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Cocoa/Cocoa.h>


@class IRCClient;
@class LogController;


@interface IRCTreeItem : NSObject <NSTableViewDataSource, NSTableViewDelegate>
{
	int uid;
	LogController* log;
	BOOL isKeyword;
	BOOL isUnread;
	BOOL isNewTalk;
}

@property (nonatomic, assign) int uid;
@property (nonatomic, retain) LogController* log;
@property (nonatomic, assign) BOOL isKeyword;
@property (nonatomic, assign) BOOL isUnread;
@property (nonatomic, assign) BOOL isNewTalk;
@property (nonatomic, readonly) BOOL isActive;
@property (nonatomic, readonly) BOOL isClient;
@property (nonatomic, readonly) IRCClient* client;
@property (nonatomic, readonly) NSString* label;
@property (nonatomic, readonly) NSString* name;

- (void)resetState;
- (int)numberOfChildren;
- (IRCTreeItem*)childAtIndex:(int)index;

@end
