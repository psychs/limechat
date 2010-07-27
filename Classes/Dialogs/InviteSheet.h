// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Foundation/Foundation.h>
#import "SheetBase.h"


@interface InviteSheet : SheetBase
{
	NSArray* nicks;
	int uid;
	
	IBOutlet NSTextField* titleLabel;
	IBOutlet NSPopUpButton* channelPopup;
}

@property (nonatomic, retain) NSArray* nicks;
@property (nonatomic, assign) int uid;

- (void)startWithChannels:(NSArray*)channels;

- (void)invite:(id)sender;

@end


@interface NSObject (InviteSheetDelegate)
- (void)inviteSheet:(InviteSheet*)sender onSelectChannel:(NSString*)channelName;
- (void)inviteSheetWillClose:(InviteSheet*)sender;
@end
