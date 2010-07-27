// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Foundation/Foundation.h>
#import "SheetBase.h"
#import "IgnoreItem.h"
#import "ListView.h"


@interface IgnoreItemSheet : SheetBase
{
	IBOutlet NSButton* nickCheck;
	IBOutlet NSPopUpButton* nickPopup;
	IBOutlet NSTextField* nickText;
	IBOutlet NSButton* messageCheck;
	IBOutlet NSPopUpButton* messagePopup;
	IBOutlet NSTextField* messageText;
	IBOutlet ListView* channelTable;
	IBOutlet NSButton* deleteChannelButton;
	
	IgnoreItem* ignore;
	BOOL newItem;
	NSMutableArray* channels;
}

@property (nonatomic, retain) IgnoreItem* ignore;
@property (nonatomic, assign) BOOL newItem;

- (void)start;

- (void)addChannel:(id)sender;
- (void)deleteChannel:(id)sender;

@end


@interface NSObject (IgnoreItemSheetDelegate)
- (void)ignoreItemSheetOnOK:(IgnoreItemSheet*)sender;
- (void)ignoreItemSheetWillClose:(IgnoreItemSheet*)sender;
@end
