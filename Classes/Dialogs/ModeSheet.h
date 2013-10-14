// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Foundation/Foundation.h>
#import "SheetBase.h"
#import "IRCChannelMode.h"


@interface ModeSheet : SheetBase

@property (nonatomic) IRCChannelMode* mode;
@property (nonatomic) NSString* channelName;
@property (nonatomic) int uid;
@property (nonatomic) int cid;

@property (nonatomic) IBOutlet NSButton* sCheck;
@property (nonatomic) IBOutlet NSButton* pCheck;
@property (nonatomic) IBOutlet NSButton* nCheck;
@property (nonatomic) IBOutlet NSButton* tCheck;
@property (nonatomic) IBOutlet NSButton* iCheck;
@property (nonatomic) IBOutlet NSButton* mCheck;
@property (nonatomic) IBOutlet NSButton* aCheck;
@property (nonatomic) IBOutlet NSButton* rCheck;
@property (nonatomic) IBOutlet NSButton* kCheck;
@property (nonatomic) IBOutlet NSButton* lCheck;
@property (nonatomic) IBOutlet NSTextField* kText;
@property (nonatomic) IBOutlet NSTextField* lText;

- (void)start;

- (void)onChangeCheck:(id)sender;

@end


@interface NSObject (ModeSheetDelegate)
- (void)modeSheetOnOK:(ModeSheet*)sender;
- (void)modeSheetWillClose:(ModeSheet*)sender;
@end
