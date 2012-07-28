// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Foundation/Foundation.h>
#import "SheetBase.h"
#import "IRCChannelMode.h"


@interface ModeSheet : SheetBase
{
    IBOutlet NSButton* sCheck;
    IBOutlet NSButton* pCheck;
    IBOutlet NSButton* nCheck;
    IBOutlet NSButton* tCheck;
    IBOutlet NSButton* iCheck;
    IBOutlet NSButton* mCheck;
    IBOutlet NSButton* aCheck;
    IBOutlet NSButton* rCheck;
    IBOutlet NSButton* kCheck;
    IBOutlet NSButton* lCheck;
    IBOutlet NSTextField* kText;
    IBOutlet NSTextField* lText;
}

@property (nonatomic, strong) IRCChannelMode* mode;
@property (nonatomic, strong) NSString* channelName;
@property (nonatomic) int uid;
@property (nonatomic) int cid;

- (void)start;

- (void)onChangeCheck:(id)sender;

@end


@interface NSObject (ModeSheetDelegate)
- (void)modeSheetOnOK:(ModeSheet*)sender;
- (void)modeSheetWillClose:(ModeSheet*)sender;
@end
