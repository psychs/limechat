// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "LogView.h"


@implementation LogView

- (void)keyDown:(NSEvent *)e
{
    if (_keyDelegate) {
        NSUInteger m = [e modifierFlags];
        BOOL ctrl = (m & NSControlKeyMask) != 0;
        BOOL alt = (m & NSAlternateKeyMask) != 0;
        BOOL cmd = (m & NSCommandKeyMask) != 0;

        if (!(ctrl || alt || cmd)) {
            if ([_keyDelegate respondsToSelector:@selector(logViewKeyDown:)]) {
                [_keyDelegate logViewKeyDown:e];
            }
            return;
        }
    }

    [super keyDown:e];
}

- (void)setFrame:(NSRect)rect
{
    if (_resizeDelegate && [_resizeDelegate respondsToSelector:@selector(logViewWillResize)]) {
        [_resizeDelegate logViewWillResize];
    }

    [super setFrame:rect];

    if (_resizeDelegate && [_resizeDelegate respondsToSelector:@selector(logViewDidResize)]) {
        [_resizeDelegate logViewDidResize];
    }
}

- (BOOL)maintainsInactiveSelection
{
    return YES;
}

- (NSString*)contentString
{
    WebFrame* frame = [self mainFrame];
    if (!frame) return @"";
    DOMHTMLDocument* doc = (DOMHTMLDocument*)[frame DOMDocument];
    if (!doc) return @"";
    DOMElement* body = [doc body];
    if (!body) return @"";
    DOMHTMLElement* root = (DOMHTMLElement*)[body parentNode];
    if (!root) return @"";
    return [root outerHTML];
}

- (void)clearSelection
{
    [self setSelectedDOMRange:nil affinity:NSSelectionAffinityDownstream];
}

- (BOOL)hasSelection
{
    return [self selection].length > 0;
}

- (NSString*)selection
{
    DOMRange* range = [self selectedDOMRange];
    if (!range) return nil;
    return [range toString];

    /*
     DOMNode* sel = [[self selectedDOMRange] cloneContents];
     if (!sel) return nil;

     NSMutableString* s = [NSMutableString string];
     DOMNodeIterator* iter = [[[self selectedFrame] DOMDocument] createNodeIterator:sel whatToShow:DOM_SHOW_TEXT filter:nil expandEntityReferences:YES];
     DOMNode* node;

     while (node = [iter nextNode]) {
     [s appendString:[node nodeValue]];
     }

     if (s.length == 0) return nil;
     return s;
     */
}

@end
