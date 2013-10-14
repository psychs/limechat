// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "ChannelDialog.h"
#import "NSWindowHelper.h"
#import "NSStringHelper.h"


@implementation ChannelDialog
{
    BOOL _isSheet;
    BOOL _isEndedSheet;
}

- (id)init
{
    self = [super init];
    if (self) {
        [NSBundle loadNibNamed:@"ChannelDialog" owner:self];
    }
    return self;
}

- (void)start
{
    _isSheet = NO;
    _isEndedSheet = NO;
    [self load];
    [self update];
    [self show];
}

- (void)startSheet
{
    _isSheet = YES;
    _isEndedSheet = NO;
    [self load];
    [self update];
    [NSApp beginSheet:_window modalForWindow:_parentWindow modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void)show
{
    if (![self.window isVisible]) {
        [self.window centerOfWindow:_parentWindow];
    }
    [self.window makeKeyAndOrderFront:nil];
}

- (void)close
{
    _delegate = nil;
    [self.window close];
}

- (void)sheetDidEnd:(NSWindow*)sender returnCode:(NSInteger)returnCode contextInfo:(void*)contextInfo
{
    _isEndedSheet = YES;
    [_window close];
}

- (void)load
{
    _nameText.stringValue = _config.name;
    _passwordText.stringValue = _config.password;
    _modeText.stringValue = _config.mode;
    _topicText.stringValue = _config.topic;

    _autoJoinCheck.state = _config.autoJoin;
    _consoleCheck.state = _config.logToConsole;
    _notifyCheck.state = _config.notify;
}

- (void)save
{
    _config.name = _nameText.stringValue;
    _config.password = _passwordText.stringValue;
    _config.mode = _modeText.stringValue;
    _config.topic = _topicText.stringValue;

    _config.autoJoin = _autoJoinCheck.state;
    _config.logToConsole = _consoleCheck.state;
    _config.notify = _notifyCheck.state;

    if (![_config.name isChannelName]) {
        _config.name = [@"#" stringByAppendingString:_config.name];
    }
}

- (void)update
{
    if (_cid < 0) {
        [self.window setTitle:@"New Channel"];
    }
    else {
        [_nameText setEditable:NO];
        [_nameText setSelectable:NO];
        [_nameText setBezeled:NO];
        [_nameText setDrawsBackground:NO];
    }

    NSString* s = _nameText.stringValue;
    [_okButton setEnabled:s.length > 0];
}

- (void)controlTextDidChange:(NSNotification*)note
{
    [self update];
}

#pragma mark - Actions

- (void)ok:(id)sender
{
    [self save];

    if ([_delegate respondsToSelector:@selector(channelDialogOnOK:)]) {
        [_delegate channelDialogOnOK:self];
    }

    [self cancel:nil];
}

- (void)cancel:(id)sender
{
    if (_isSheet) {
        [NSApp endSheet:_window];
    }
    else {
        [self.window close];
    }
}

#pragma mark - NSWindow Delegate

- (void)windowWillClose:(NSNotification*)note
{
    if (_isSheet && !_isEndedSheet) {
        [NSApp endSheet:_window];
    }

    if ([_delegate respondsToSelector:@selector(channelDialogWillClose:)]) {
        [_delegate channelDialogWillClose:self];
    }
}

@end
