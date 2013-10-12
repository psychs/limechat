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
    [sCheck setState:_mode.s];
    [pCheck setState:_mode.p];
    [nCheck setState:_mode.n];
    [tCheck setState:_mode.t];
    [iCheck setState:_mode.i];
    [mCheck setState:_mode.m];
    [aCheck setState:_mode.a];
    [rCheck setState:_mode.r];
    [kCheck setState:_mode.k.length > 0];
    [lCheck setState:_mode.l > 0];

    [kText setStringValue:_mode.k ?: @""];
    [lText setStringValue:[NSString stringWithFormat:@"%d", _mode.l]];

    [self updateTextFields];

    if ([_channelName hasPrefix:@"!"]) {
        [aCheck setEnabled:YES];
        [rCheck setEnabled:YES];
    }
    else if ([_channelName hasPrefix:@"&"]) {
        [aCheck setEnabled:YES];
        [rCheck setEnabled:NO];
    }
    else {
        [aCheck setEnabled:NO];
        [rCheck setEnabled:NO];
    }

    [sheet makeFirstResponder:sCheck];
    [self startSheet];
}

- (void)updateTextFields
{
    [kText setEnabled:kCheck.state == NSOnState];
    [lText setEnabled:lCheck.state == NSOnState];
}

- (void)onChangeCheck:(id)sender
{
    [self updateTextFields];

    if ([sCheck state] == NSOnState && [pCheck state] == NSOnState) {
        if (sender == sCheck) {
            [pCheck setState:NSOffState];
        }
        else {
            [sCheck setState:NSOffState];
        }
    }
}

- (void)ok:(id)sender
{
    _mode.s = [sCheck state] == NSOnState;
    _mode.p = [pCheck state] == NSOnState;
    _mode.n = [nCheck state] == NSOnState;
    _mode.t = [tCheck state] == NSOnState;
    _mode.i = [iCheck state] == NSOnState;
    _mode.m = [mCheck state] == NSOnState;
    _mode.a = [aCheck state] == NSOnState;
    _mode.r = [rCheck state] == NSOnState;

    if ([kCheck state] == NSOnState) {
        _mode.k = [kText stringValue];
    }
    else {
        _mode.k = @"";
    }

    if ([lCheck state] == NSOnState) {
        _mode.l = [[lText stringValue] intValue];
    }
    else {
        _mode.l = 0;
    }

    if ([self.delegate respondsToSelector:@selector(modeSheetOnOK:)]) {
        [self.delegate modeSheetOnOK:self];
    }

    [super ok:sender];
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification*)note
{
    if ([self.delegate respondsToSelector:@selector(modeSheetWillClose:)]) {
        [self.delegate modeSheetWillClose:self];
    }
}

@end
