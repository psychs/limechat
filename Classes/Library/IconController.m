// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "IconController.h"


@implementation IconController
{
    BOOL _highlight;
    BOOL _newTalk;
}

- (void)setHighlight:(BOOL)aHighlight newTalk:(BOOL)aNewTalk
{
    if (_highlight == aHighlight && _newTalk == aNewTalk) {
        return;
    }

    _highlight = aHighlight;
    _newTalk = aNewTalk;

    NSImage* icon = [NSImage imageNamed:@"NSApplicationIcon"];

    if (_highlight || _newTalk) {
        NSSize iconSize = icon.size;
        NSImage* badge = _highlight ? [NSImage imageNamed:@"redbadge"] : [NSImage imageNamed:@"bluebadge"];
        if (badge) {
            NSSize size = badge.size;
            int w = size.width;
            int h = size.height;
            int x = iconSize.width - w;
            int y = iconSize.height - h;
            NSRect rect = NSMakeRect(x, y, w, h);
            NSRect sourceRect = NSMakeRect(0, 0, size.width, size.height);
            NSDictionary* hints = @{NSImageHintInterpolation:@(NSImageInterpolationHigh)};

            icon = [icon copy];
            [icon lockFocus];
            [badge drawInRect:rect fromRect:sourceRect operation:NSCompositeSourceOver fraction:1 respectFlipped:YES hints:hints];
            [icon unlockFocus];
        }
    }

    [NSApp setApplicationIconImage:icon];
}

@end
