// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "InviteSheet.h"


@interface InviteSheet (Private)
@end


@implementation InviteSheet

@synthesize nicks;
@synthesize uid;

- (id)init
{
	self = [super init];
	if (self) {
		[NSBundle loadNibNamed:@"InviteSheet" owner:self];
	}
	return self;
}

- (void)dealloc
{
	[nicks release];
	[super dealloc];
}

- (void)startWithChannels:(NSArray*)channels
{
	NSString* target;
	if (nicks.count == 1) {
		target = [nicks objectAtIndex:0];
	}
	else if (nicks.count == 2) {
		NSString* first = [nicks objectAtIndex:0];
		NSString* second = [nicks objectAtIndex:1];
		target = [NSString stringWithFormat:@"%@ and %@", first, second];
	}
	else {
		target = [NSString stringWithFormat:@"%d users", nicks.count];
	}
	titleLabel.stringValue = [NSString stringWithFormat:@"Invite %@ to:", target];
	
	for (NSString* s in channels) {
		[channelPopup addItemWithTitle:s];
	}
	
	[self startSheet];
}

- (void)invite:(id)sender
{
	NSString* channelName = [[channelPopup selectedItem] title];
	
	if ([delegate respondsToSelector:@selector(inviteSheet:onSelectChannel:)]) {
		[delegate inviteSheet:self onSelectChannel:channelName];
	}
	
	[self endSheet];
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification*)note
{
	if ([delegate respondsToSelector:@selector(inviteSheetWillClose:)]) {
		[delegate inviteSheetWillClose:self];
	}
}

@end
