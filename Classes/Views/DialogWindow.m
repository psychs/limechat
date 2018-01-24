// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "DialogWindow.h"


@implementation DialogWindow
{
    BOOL _isSheet;
    NSWindow *_ownerWindow;
}

- (void)startSheetModalForWindow:(NSWindow *)parentWindow
{
    _isSheet = YES;
    _ownerWindow = parentWindow;
    [_ownerWindow beginSheet:self completionHandler:^(NSModalResponse returnCode) {
        [self close];
    }];
}

- (void)endSheet
{
    [_ownerWindow endSheet:self];
    _ownerWindow = nil;
}

- (void)closeWindowOrSheet
{
    if (_isSheet) {
        [self endSheet];
    } else {
        [self close];
    }
}

- (void)sendEvent:(NSEvent *)e
{
    if ([e type] == NSKeyDown) {
        NSTextInputContext *context = [NSTextInputContext currentInputContext];
        id<NSTextInputClient> client = context.client;
        if (!client || client.markedRange.length == 0) {
            int k = [e keyCode];
            NSUInteger m = [e modifierFlags];
            BOOL shift = (m & NSShiftKeyMask) != 0;
            BOOL ctrl = (m & NSControlKeyMask) != 0;
            BOOL alt = (m & NSAlternateKeyMask) != 0;
            BOOL cmd = (m & NSCommandKeyMask) != 0;

            if (!(shift || ctrl || alt || cmd)) {
                // no mods
                switch (k) {
                    case 0x35:	// esc
                        [self closeWindowOrSheet];
                        return;
                }
            }
        }
    }

    [super sendEvent:e];
}

@end
