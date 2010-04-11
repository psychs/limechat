// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import <Foundation/Foundation.h>
#import "SheetBase.h"


@interface TopicSheet : SheetBase
{
	int uid;
	int cid;

	IBOutlet NSTextField* text;
}

@property (nonatomic, assign) int uid;
@property (nonatomic, assign) int cid;

- (void)start:(NSString*)topic;

@end


@interface NSObject (TopicSheetDelegate)
- (void)topicSheet:(TopicSheet*)sender onOK:(NSString*)topic;
- (void)topicSheetWillClose:(TopicSheet*)sender;
@end
