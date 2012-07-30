// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "IconController.h"


@implementation IconController
{
    BOOL highlight;
    BOOL newTalk;
}

- (void)setHighlight:(BOOL)aHighlight newTalk:(BOOL)aNewTalk
{
    if (highlight == aHighlight && newTalk == aNewTalk) {
        return;
    }
    
    highlight = aHighlight;
    newTalk = aNewTalk;
    
    NSImage* icon = [NSImage imageNamed:@"NSApplicationIcon"];
    
    if (highlight || newTalk) {
        NSSize iconSize = icon.size;
        NSImage* badge = highlight ? [NSImage imageNamed:@"redbadge"] : [NSImage imageNamed:@"bluebadge"];
        if (badge) {
            NSSize size = badge.size;
            int w = size.width;
            int h = size.height;
            int x = iconSize.width - w;
            int y = iconSize.height - h;
            NSRect rect = NSMakeRect(x, y, w, h);
            NSRect sourceRect = NSMakeRect(0, 0, size.width, size.height);
            NSDictionary* hints = @{NSImageHintInterpolation:[NSNumber numberWithInt:NSImageInterpolationHigh]};

            icon = [[icon copy] autorelease];
            [icon lockFocus];
            [badge drawInRect:rect fromRect:sourceRect operation:NSCompositeSourceOver fraction:1 respectFlipped:YES hints:hints];
            [icon unlockFocus];
        }
    }

    [NSApp setApplicationIconImage:icon];
}

@end
