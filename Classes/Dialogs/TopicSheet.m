// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "TopicSheet.h"


@implementation TopicSheet

- (id)init
{
    self = [super init];
    if (self) {
        [NSBundle loadNibNamed:@"TopicSheet" owner:self];
    }
    return self;
}

- (void)start:(NSString*)topic
{
    [_text setStringValue:topic ?: @""];
    [self startSheet];
}

- (void)ok:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(topicSheet:onOK:)]) {
        [self.delegate topicSheet:self onOK:[_text stringValue]];
    }

    [super ok:nil];
}

#pragma mark - NSWindow Delegate

- (void)windowWillClose:(NSNotification*)note
{
    if ([self.delegate respondsToSelector:@selector(topicSheetWillClose:)]) {
        [self.delegate topicSheetWillClose:self];
    }
}

@end
