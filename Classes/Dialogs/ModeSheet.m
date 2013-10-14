// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "ModeSheet.h"


@implementation ModeSheet

- (id)init
{
    self = [super init];
    if (self) {
        [NSBundle loadNibNamed:@"ModeSheet" owner:self];
    }
    return self;
}

- (void)start
{
    [_sCheck setState:_mode.s];
    [_pCheck setState:_mode.p];
    [_nCheck setState:_mode.n];
    [_tCheck setState:_mode.t];
    [_iCheck setState:_mode.i];
    [_mCheck setState:_mode.m];
    [_aCheck setState:_mode.a];
    [_rCheck setState:_mode.r];
    [_kCheck setState:_mode.k.length > 0];
    [_lCheck setState:_mode.l > 0];

    [_kText setStringValue:_mode.k ?: @""];
    [_lText setStringValue:[NSString stringWithFormat:@"%d", _mode.l]];

    [self updateTextFields];

    if ([_channelName hasPrefix:@"!"]) {
        [_aCheck setEnabled:YES];
        [_rCheck setEnabled:YES];
    }
    else if ([_channelName hasPrefix:@"&"]) {
        [_aCheck setEnabled:YES];
        [_rCheck setEnabled:NO];
    }
    else {
        [_aCheck setEnabled:NO];
        [_rCheck setEnabled:NO];
    }

    [self.sheet makeFirstResponder:_sCheck];
    [self startSheet];
}

- (void)updateTextFields
{
    [_kText setEnabled:_kCheck.state == NSOnState];
    [_lText setEnabled:_lCheck.state == NSOnState];
}

- (void)onChangeCheck:(id)sender
{
    [self updateTextFields];

    if ([_sCheck state] == NSOnState && [_pCheck state] == NSOnState) {
        if (sender == _sCheck) {
            [_pCheck setState:NSOffState];
        }
        else {
            [_sCheck setState:NSOffState];
        }
    }
}

- (void)ok:(id)sender
{
    _mode.s = [_sCheck state] == NSOnState;
    _mode.p = [_pCheck state] == NSOnState;
    _mode.n = [_nCheck state] == NSOnState;
    _mode.t = [_tCheck state] == NSOnState;
    _mode.i = [_iCheck state] == NSOnState;
    _mode.m = [_mCheck state] == NSOnState;
    _mode.a = [_aCheck state] == NSOnState;
    _mode.r = [_rCheck state] == NSOnState;

    if ([_kCheck state] == NSOnState) {
        _mode.k = [_kText stringValue];
    }
    else {
        _mode.k = @"";
    }

    if ([_lCheck state] == NSOnState) {
        _mode.l = [[_lText stringValue] intValue];
    }
    else {
        _mode.l = 0;
    }

    if ([self.delegate respondsToSelector:@selector(modeSheetOnOK:)]) {
        [self.delegate modeSheetOnOK:self];
    }

    [super ok:sender];
}

#pragma mark - NSWindow Delegate

- (void)windowWillClose:(NSNotification*)note
{
    if ([self.delegate respondsToSelector:@selector(modeSheetWillClose:)]) {
        [self.delegate modeSheetWillClose:self];
    }
}

@end
