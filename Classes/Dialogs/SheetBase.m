// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "SheetBase.h"


@implementation SheetBase

- (id)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)startSheet
{
    [NSApp beginSheet:_sheet modalForWindow:_window modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void)endSheet
{
    [NSApp endSheet:_sheet];
}

- (void)sheetDidEnd:(NSWindow*)sender returnCode:(NSInteger)returnCode contextInfo:(void*)contextInfo
{
    [_sheet close];
}

- (void)ok:(id)sender
{
    [self endSheet];
}

- (void)cancel:(id)sender
{
    [self endSheet];
}

@end
