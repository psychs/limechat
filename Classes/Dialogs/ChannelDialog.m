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

@synthesize window;

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
    [NSApp beginSheet:window modalForWindow:_parentWindow modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
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
    [window close];
}

- (void)load
{
    nameText.stringValue = _config.name;
    passwordText.stringValue = _config.password;
    modeText.stringValue = _config.mode;
    topicText.stringValue = _config.topic;

    autoJoinCheck.state = _config.autoJoin;
    consoleCheck.state = _config.logToConsole;
    growlCheck.state = _config.growl;
}

- (void)save
{
    _config.name = nameText.stringValue;
    _config.password = passwordText.stringValue;
    _config.mode = modeText.stringValue;
    _config.topic = topicText.stringValue;

    _config.autoJoin = autoJoinCheck.state;
    _config.logToConsole = consoleCheck.state;
    _config.growl = growlCheck.state;

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
        [nameText setEditable:NO];
        [nameText setSelectable:NO];
        [nameText setBezeled:NO];
        [nameText setDrawsBackground:NO];
    }

    NSString* s = nameText.stringValue;
    [okButton setEnabled:s.length > 0];
}

- (void)controlTextDidChange:(NSNotification*)note
{
    [self update];
}

#pragma mark -
#pragma mark Actions

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
        [NSApp endSheet:window];
    }
    else {
        [self.window close];
    }
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification*)note
{
    if (_isSheet && !_isEndedSheet) {
        [NSApp endSheet:window];
    }

    if ([_delegate respondsToSelector:@selector(channelDialogWillClose:)]) {
        [_delegate channelDialogWillClose:self];
    }
}

@end
