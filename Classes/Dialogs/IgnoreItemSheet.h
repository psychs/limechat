// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Foundation/Foundation.h>
#import "SheetBase.h"
#import "IgnoreItem.h"
#import "ListView.h"


@interface IgnoreItemSheet : SheetBase

@property (nonatomic) IgnoreItem* ignore;
@property (nonatomic) BOOL newItem;

@property (nonatomic) IBOutlet NSButton* nickCheck;
@property (nonatomic) IBOutlet NSPopUpButton* nickPopup;
@property (nonatomic) IBOutlet NSTextField* nickText;
@property (nonatomic) IBOutlet NSButton* messageCheck;
@property (nonatomic) IBOutlet NSPopUpButton* messagePopup;
@property (nonatomic) IBOutlet NSTextField* messageText;
@property (nonatomic) IBOutlet ListView* channelTable;
@property (nonatomic) IBOutlet NSButton* deleteChannelButton;

- (void)start;

- (void)addChannel:(id)sender;
- (void)deleteChannel:(id)sender;

@end


@interface NSObject (IgnoreItemSheetDelegate)
- (void)ignoreItemSheetOnOK:(IgnoreItemSheet*)sender;
- (void)ignoreItemSheetWillClose:(IgnoreItemSheet*)sender;
@end
