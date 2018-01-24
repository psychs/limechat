// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "PasteSheet.h"
#import "NSStringHelper.h"

static NSArray* SYNTAXES;

@implementation PasteSheet

- (id)init
{
    self = [super init];
    if (self) {
        [[NSBundle mainBundle] loadNibNamed:@"PasteSheet" owner:self topLevelObjects:nil];

        if (!SYNTAXES) {
            SYNTAXES = [NSArray arrayWithObjects:@"privmsg", @"notice", nil];
        }
    }
    return self;
}

- (void)start
{
    if (_editMode) {
        NSArray* lines = [_originalText splitIntoLines];
        _isShortText = lines.count <= 3;
        [self.sheet makeFirstResponder:_bodyText];
    }

    [_commandPopup selectItemWithTag:[self tagFromSyntax:_command]];
    [_bodyText setString:_originalText];

    if (!NSEqualSizes(_size, NSZeroSize)) {
        [self.sheet setContentSize:_size];
    }

    [self startSheet];
}

- (void)sendInChannel:(id)sender
{
    _command = [self syntaxFromTag:_commandPopup.selectedTag];

    NSString* s = _bodyText.string;

    if ([self.delegate respondsToSelector:@selector(pasteSheet:onPasteText:)]) {
        [self.delegate pasteSheet:self onPasteText:s];
    }

    [self endSheet];
}

- (void)cancel:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(pasteSheetOnCancel:)]) {
        [self.delegate pasteSheetOnCancel:self];
    }

    [super cancel:nil];
}

- (int)tagFromSyntax:(NSString *)s
{
    NSUInteger n = [SYNTAXES indexOfObject:s];
    if (n != NSNotFound) {
        return n;
    }
    return -1;
}

- (NSString *)syntaxFromTag:(int)tag
{
    if (0 <= tag && tag < SYNTAXES.count) {
        return [SYNTAXES objectAtIndex:tag];
    }
    return nil;
}

#pragma mark - NSWindow Delegate

- (void)windowWillClose:(NSNotification*)note
{
    _command = [self syntaxFromTag:_commandPopup.selectedTag];

    NSView* contentView = [self.sheet contentView];
    _size = contentView.frame.size;

    if ([self.delegate respondsToSelector:@selector(pasteSheetWillClose:)]) {
        [self.delegate pasteSheetWillClose:self];
    }
}

@end
