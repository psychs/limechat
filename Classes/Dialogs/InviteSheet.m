// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "InviteSheet.h"


@implementation InviteSheet

- (id)init
{
    self = [super init];
    if (self) {
        [NSBundle loadNibNamed:@"InviteSheet" owner:self];
    }
    return self;
}

- (void)startWithChannels:(NSArray*)channels
{
    NSString* target;
    if (_nicks.count == 1) {
        target = [_nicks objectAtIndex:0];
    }
    else if (_nicks.count == 2) {
        NSString* first = [_nicks objectAtIndex:0];
        NSString* second = [_nicks objectAtIndex:1];
        target = [NSString stringWithFormat:@"%@ and %@", first, second];
    }
    else {
        target = [NSString stringWithFormat:@"%d users", (int)_nicks.count];
    }
    _titleLabel.stringValue = [NSString stringWithFormat:@"Invite %@ to:", target];

    for (NSString* s in channels) {
        [_channelPopup addItemWithTitle:s];
    }

    [self startSheet];
}

- (void)invite:(id)sender
{
    NSString* channelName = [[_channelPopup selectedItem] title];

    if ([self.delegate respondsToSelector:@selector(inviteSheet:onSelectChannel:)]) {
        [self.delegate inviteSheet:self onSelectChannel:channelName];
    }

    [self endSheet];
}

#pragma mark - NSWindow Delegate

- (void)windowWillClose:(NSNotification*)note
{
    if ([self.delegate respondsToSelector:@selector(inviteSheetWillClose:)]) {
        [self.delegate inviteSheetWillClose:self];
    }
}

@end
