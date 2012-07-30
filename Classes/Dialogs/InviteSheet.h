// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Foundation/Foundation.h>
#import "SheetBase.h"


@interface InviteSheet : SheetBase
{
    IBOutlet NSTextField* titleLabel;
    IBOutlet NSPopUpButton* channelPopup;

    NSArray* nicks;
    int uid;
}

@property (nonatomic, strong) NSArray* nicks;
@property (nonatomic) int uid;

- (void)startWithChannels:(NSArray*)channels;

- (void)invite:(id)sender;

@end


@interface NSObject (InviteSheetDelegate)
- (void)inviteSheet:(InviteSheet*)sender onSelectChannel:(NSString*)channelName;
- (void)inviteSheetWillClose:(InviteSheet*)sender;
@end
