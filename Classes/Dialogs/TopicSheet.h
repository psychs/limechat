// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Foundation/Foundation.h>
#import "SheetBase.h"


@interface TopicSheet : SheetBase

@property (nonatomic) int uid;
@property (nonatomic) int cid;

@property (nonatomic) IBOutlet NSTextField* text;

- (void)start:(NSString*)topic;

@end


@interface NSObject (TopicSheetDelegate)
- (void)topicSheet:(TopicSheet*)sender onOK:(NSString*)topic;
- (void)topicSheetWillClose:(TopicSheet*)sender;
@end
