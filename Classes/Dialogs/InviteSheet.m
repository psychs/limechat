// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "InviteSheet.h"


@interface InviteSheet (Private)
@end


@implementation InviteSheet

@synthesize nicks;
@synthesize uid;

- (id)init
{
	if (self = [super init]) {
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
