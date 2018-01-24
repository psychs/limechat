// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "WelcomeDialog.h"
#import "ServerDialog.h"
#import "NSStringHelper.h"


@implementation WelcomeDialog
{
    NSMutableArray* _channels;
}

- (id)init
{
    self = [super init];
    if (self) {
        [[NSBundle mainBundle] loadNibNamed:@"WelcomeDialog" owner:self topLevelObjects:nil];

        _channels = [NSMutableArray new];

        NSArray* servers = [ServerDialog availableServers];
        for (NSString* s in servers) {
            [_hostCombo addItemWithObjectValue:s];
        }
    }
    return self;
}

- (void)dealloc
{
    _channelTable.delegate = nil;
    _channelTable.dataSource = nil;
}

- (void)show
{
    [self tableViewSelectionIsChanging:nil];
    [self updateOKButton];

    if (![self.window isVisible]) {
        [self.window center];

        NSString* username = NSUserName();
        username = [username stringByReplacingOccurrencesOfString:@" " withString:@""];

        NSRange range = [username rangeOfString:@"[a-zA-Z][-_a-zA-Z0-9]*" options:NSRegularExpressionSearch];
        if (range.location != NSNotFound) {
            _nickText.stringValue = [username substringWithRange:range];
        }
    }

    [self.window makeKeyAndOrderFront:nil];
}

- (void)close
{
    _delegate = nil;
    [self.window close];
}

- (void)onOK:(id)sender
{
    [self.window endEditingFor:nil];

    /*
     NSText* fieldEditor = [self.window fieldEditor:NO forObject:channelTable];
     if (fieldEditor) {
     [[channelTable cell] endEditing:fieldEditor];
     NSInteger n = [channelTable editedRow];
     if (n != NSNotFound) {
     NSString* s = [[[fieldEditor string] copy] autorelease];
     if (n < channels.count) {
     [channels replaceObjectAtIndex:n withObject:s];
     }
     }
     }
     */

    NSMutableSet* set = [NSMutableSet set];
    NSMutableArray* chans = [NSMutableArray array];

    for (NSString* chname in _channels) {
        NSString* s = chname;
        if (s.length > 0) {
            if (![s isChannelName]) {
                s = [@"#" stringByAppendingString:s];
            }

            if (![set containsObject:s]) {
                [chans addObject:s];
                [set addObject:s];
            }
        }
    }

    NSMutableDictionary* dic = [NSMutableDictionary dictionary];
    [dic setObject:_nickText.stringValue forKey:@"nick"];
    [dic setObject:_hostCombo.stringValue forKey:@"host"];
    [dic setObject:chans forKey:@"channels"];
    [dic setObject:@((BOOL)_autoConnectCheck.state) forKey:@"autoConnect"];

    if ([_delegate respondsToSelector:@selector(welcomeDialog:onOK:)]) {
        [_delegate welcomeDialog:self onOK:dic];
    }

    [self.window close];
}

- (void)onCancel:(id)sender
{
    [self.window close];
}

- (void)onAddChannel:(id)sender
{
    [_channels addObject:@""];
    [_channelTable reloadData];
    int row = _channels.count - 1;
    [_channelTable selectItemAtIndex:row];
    [_channelTable editColumn:0 row:row withEvent:nil select:YES];
}

- (void)onDeleteChannel:(id)sender
{
    NSInteger n = [_channelTable selectedRow];
    if (n >= 0) {
        [_channels removeObjectAtIndex:n];
        [_channelTable reloadData];
        int count = _channels.count;
        if (count <= n) n = count - 1;
        if (n >= 0) {
            [_channelTable selectItemAtIndex:n];
        }
        [self tableViewSelectionIsChanging:nil];
    }
}

- (void)controlTextDidChange:(NSNotification*)note
{
    [self updateOKButton];
}

- (void)onHostComboChanged:(id)sender
{
    [self updateOKButton];
}

- (void)updateOKButton
{
    NSString* nick = _nickText.stringValue;
    NSString* host = _hostCombo.stringValue;
    [_okButton setEnabled:nick.length > 0 && host.length > 0];
}

#pragma mark - NSTableViwe Delegate

- (void)textDidEndEditing:(NSNotification*)note
{
    NSInteger n = [_channelTable editedRow];
    if (n >= 0) {
        NSString* s = [[[[note object] textStorage] string] copy];
        [_channels replaceObjectAtIndex:n withObject:s];
        [_channelTable reloadData];
        [_channelTable selectItemAtIndex:n];
        [self tableViewSelectionIsChanging:nil];
    }
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)sender
{
    return _channels.count;
}

- (id)tableView:(NSTableView *)sender objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
    return [_channels objectAtIndex:row];
}

- (void)tableViewSelectionIsChanging:(NSNotification *)note
{
    [_deleteChannelButton setEnabled:[_channelTable selectedRow] >= 0];
}

#pragma mark - NSWindow Delegate

- (void)windowWillClose:(NSNotification*)note
{
    if ([_delegate respondsToSelector:@selector(welcomeDialogWillClose:)]) {
        [_delegate welcomeDialogWillClose:self];
    }
}

@end
