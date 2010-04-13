// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

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
