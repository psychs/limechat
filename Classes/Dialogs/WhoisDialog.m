// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "WhoisDialog.h"
#import "NSRectHelper.h"


#define ROTATE_COUNT    10
#define OFFSET          20


static int windowPlace;


@implementation WhoisDialog

- (id)init
{
    self = [super init];
    if (self) {
        [NSBundle loadNibNamed:@"WhoisDialog" owner:self];
    }
    return self;
}

- (void)setIsOperator:(BOOL)value
{
    _isOperator = value;
    [self updateNick];
}

- (void)setNick:(NSString *)value
{
    if (_nick != value) {
        _nick = value;
        [self updateNick];
        [self.window setTitle:_nick];
    }
}

- (void)startWithNick:(NSString*)aNick username:(NSString*)username address:(NSString*)address realname:(NSString*)realname
{
    [self setNick:aNick username:username address:address realname:realname];
    [self.window makeFirstResponder:_closeButton];
    [self show];
}

- (void)setNick:(NSString*)aNick username:(NSString*)username address:(NSString*)address realname:(NSString*)realname
{
    self.nick = aNick;
    [_logInText setStringValue:username];
    [_addressText setStringValue:address];
    [_realnameText setStringValue:realname];
    [self setAwayMessage:@""];
    [_channelsCombo removeAllItems];
    [self updateChannels];
}

- (void)setChannels:(NSArray*)channels
{
    [_channelsCombo addItemsWithTitles:channels];
    [self updateChannels];
}

- (void)setServer:(NSString*)server serverInfo:(NSString*)info
{
    [_serverText setStringValue:server];
    [_serverInfoText setStringValue:info];
}

- (void)setAwayMessage:(NSString*)value
{
    [_awayText setStringValue:value];
}

- (void)setIdle:(NSString*)idle signOn:(NSString*)signOn
{
    [_idleText setStringValue:idle];
    [_signOnText setStringValue:signOn];
}

- (void)updateNick
{
    NSString* s = _isOperator ? [_nick stringByAppendingString:@" (IRC operator)"] : _nick;
    [_nickText setStringValue:s];
}

- (void)updateChannels
{
    if ([_channelsCombo numberOfItems]) {
        NSMenuItem* sel = [_channelsCombo selectedItem];
        if (sel && sel.title.length) {
            [_joinButton setEnabled:YES];
            return;
        }
    }

    [_joinButton setEnabled:NO];
}

- (void)show
{
    if (![self.window isVisible]) {
        NSScreen* screen = [[NSApp mainWindow] screen] ?: [NSScreen mainScreen];
        if (screen) {
            NSSize size = self.window.frame.size;
            NSPoint p = NSRectCenter([screen visibleFrame]);
            p.x -= size.width/2;
            p.y -= size.width/2;
            p.x += OFFSET * (windowPlace - ROTATE_COUNT/2);
            p.y -= OFFSET * (windowPlace - ROTATE_COUNT/2);
            [self.window setFrameOrigin:p];

            ++windowPlace;
            if (windowPlace >= ROTATE_COUNT) {
                windowPlace = 0;
            }
        }
    }

    [self.window makeKeyAndOrderFront:nil];
}

- (void)close
{
    _delegate = nil;
    [self.window close];
}

- (void)onClose:(id)sender
{
    [self.window close];
}

- (void)onTalk:(id)sender
{
    if ([_delegate respondsToSelector:@selector(whoisDialogOnTalk:)]) {
        [_delegate whoisDialogOnTalk:self];
    }
}

- (void)onUpdate:(id)sender
{
    if ([_delegate respondsToSelector:@selector(whoisDialogOnUpdate:)]) {
        [_delegate whoisDialogOnUpdate:self];
    }
}

- (void)onJoin:(id)sender
{
    NSMenuItem* sel = [_channelsCombo selectedItem];
    if (!sel) return;
    NSString* chname = sel.title;
    if ([chname hasPrefix:@"@"] || [chname hasPrefix:@"+"]) {
        chname = [chname substringFromIndex:1];
    }

    if ([_delegate respondsToSelector:@selector(whoisDialogOnJoin:channel:)]) {
        [_delegate whoisDialogOnJoin:self channel:chname];
    }
}

#pragma mark - NSWindow Delegate

- (void)windowWillClose:(NSNotification*)note
{
    if ([_delegate respondsToSelector:@selector(whoisDialogWillClose:)]) {
        [_delegate whoisDialogWillClose:self];
    }
}

@end
