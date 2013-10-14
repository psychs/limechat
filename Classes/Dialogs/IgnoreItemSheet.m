// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "IgnoreItemSheet.h"


@implementation IgnoreItemSheet
{
    NSMutableArray* _channels;
}

- (id)init
{
    self = [super init];
    if (self) {
        [NSBundle loadNibNamed:@"IgnoreItemSheet" owner:self];
    }
    return self;
}

- (void)start
{
    //
    // load
    //

    if (_ignore.nick.length) {
        _nickCheck.state = NSOnState;
        [_nickPopup selectItemWithTag:_ignore.useRegexForNick ? 1 : 0];
        _nickText.stringValue = _ignore.nick;
    }
    else {
        _nickCheck.state = NSOffState;
    }

    if (_ignore.text.length) {
        _messageCheck.state = NSOnState;
        [_messagePopup selectItemWithTag:_ignore.useRegexForText ? 1 : 0];
        _messageText.stringValue = _ignore.text;
    }
    else {
        _messageCheck.state = NSOffState;
    }

    _channels = [_ignore.channels mutableCopy];
    if (!_channels) {
        _channels = [NSMutableArray new];
    }
    [self reloadChannelTable];
    [self updateButtons];

    [self startSheet];
}

- (void)reloadChannelTable
{
    [_channelTable reloadData];
}

- (void)updateButtons
{
    NSInteger i = [_channelTable selectedRow];
    BOOL enabled = (i >= 0);
    [_deleteChannelButton setEnabled:enabled];
}

- (void)addChannel:(id)sender
{
    [_channels addObject:@""];
    [self reloadChannelTable];

    NSInteger row = [_channelTable numberOfRows] - 1;
    [_channelTable scrollRowToVisible:row];
    [_channelTable editColumn:0 row:row withEvent:nil select:YES];
}

- (void)deleteChannel:(id)sender
{
    NSInteger i = [_channelTable selectedRow];
    if (i < 0) return;

    [_channels removeObjectAtIndex:i];

    int count = _channels.count;
    if (count) {
        if (count <= i) {
            [_channelTable selectItemAtIndex:count - 1];
        }
        else {
            [_channelTable selectItemAtIndex:i];
        }
    }

    [self reloadChannelTable];
}

- (void)ok:(id)sender
{
    //
    // save
    //

    NSString* nick = _nickText.stringValue;
    NSString* message = _messageText.stringValue;

    if (_nickCheck.state == NSOnState && nick.length) {
        _ignore.nick = nick;
        _ignore.useRegexForNick = _nickPopup.selectedItem.tag == 1;
    }
    else {
        _ignore.nick = nil;
    }

    if (_messageCheck.state == NSOnState && message.length) {
        _ignore.text = message;
        _ignore.useRegexForText = _messagePopup.selectedItem.tag == 1;
    }
    else {
        _ignore.text = nil;
    }

    NSMutableSet* channelSet = [NSMutableSet set];
    NSMutableArray* channelAry = [NSMutableArray array];
    for (NSString* e in _channels) {
        if (e.length && ![channelSet containsObject:e]) {
            [channelAry addObject:e];
            [channelSet addObject:e];
        }
    }
    [channelAry sortUsingSelector:@selector(caseInsensitiveCompare:)];
    _ignore.channels = channelAry;

    //
    // call delegate
    //

    if ([self.delegate respondsToSelector:@selector(ignoreItemSheetOnOK:)]) {
        [self.delegate ignoreItemSheetOnOK:self];
    }

    [super ok:sender];
}

#pragma mark - NSWindow Delegate

- (void)windowWillClose:(NSNotification*)note
{
    if ([self.delegate respondsToSelector:@selector(ignoreItemSheetWillClose:)]) {
        [self.delegate ignoreItemSheetWillClose:self];
    }
}

#pragma mark - NSTableViwe Delegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)sender
{
    return _channels.count;
}

- (id)tableView:(NSTableView *)sender objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
    return [_channels objectAtIndex:row];
}

- (void)tableView:(NSTableView *)sender setObjectValue:(id)obj forTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
    [_channels replaceObjectAtIndex:row withObject:obj];
}

- (void)tableViewSelectionDidChange:(NSNotification *)note
{
    [self updateButtons];
}

@end
