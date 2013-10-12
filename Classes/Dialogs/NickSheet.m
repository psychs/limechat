// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "NickSheet.h"


@implementation NickSheet

- (id)init
{
    self = [super init];
    if (self) {
        [NSBundle loadNibNamed:@"NickSheet" owner:self];
    }
    return self;
}

- (void)start:(NSString*)nick
{
    [currentText setStringValue:nick];
    [newText setStringValue:nick];
    [sheet makeFirstResponder:newText];

    [self startSheet];
}

- (void)ok:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(nickSheet:didInputNick:)]) {
        [self.delegate nickSheet:self didInputNick:newText.stringValue];
    }

    [super ok:sender];
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification*)note
{
    if ([self.delegate respondsToSelector:@selector(nickSheetWillClose:)]) {
        [self.delegate nickSheetWillClose:self];
    }
}

@end
