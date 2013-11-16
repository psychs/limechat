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
    [_sheet startSheetModalForWindow:_parentWindow];
}

- (void)endSheet
{
    [_sheet endSheet];
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
