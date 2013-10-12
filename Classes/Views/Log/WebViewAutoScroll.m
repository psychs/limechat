// Created by Allan Odgaard.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "WebViewAutoScroll.h"


@implementation WebViewAutoScroll
{
    NSRect lastFrame, lastVisibleRect;
}

- (void)scrollViewToBottom:(NSView*)aView
{
    NSRect visibleRect = [aView visibleRect];
    visibleRect.origin.y = NSHeight([aView frame]) - NSHeight(visibleRect);
    [aView scrollRectToVisible:visibleRect];
}

- (void)dealloc
{
    self.webFrame = nil;
}

- (void)setWebFrame:(WebFrameView*)aWebFrame
{
    if(aWebFrame == _webFrame)
        return;

    //[webFrame release];
    //webFrame = [aWebFrame retain];
    _webFrame = aWebFrame;

    if(_webFrame)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(webViewDidChangeFrame:) name:NSViewFrameDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(webViewDidChangeBounds:) name:NSViewBoundsDidChangeNotification object:nil];

        lastFrame = [[_webFrame documentView] frame];
        lastVisibleRect = [[_webFrame documentView] visibleRect];
    }
    else
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewBoundsDidChangeNotification object:nil];
    }
}

- (void)webViewDidChangeBounds:(NSNotification*)aNotification
{
    NSClipView* clipView = [[[_webFrame documentView] enclosingScrollView] contentView];
    if(clipView != [aNotification object])
        return;

    //LOG(@"bounds changed: %@ → %@", NSStringFromRect(lastVisibleRect), NSStringFromRect([[clipView documentView] visibleRect]));
    lastVisibleRect = [[clipView documentView] visibleRect];

    [_scroller updateScroller];
}

- (void)webViewDidChangeFrame:(NSNotification*)aNotification
{
    NSView* view = [aNotification object];
    if(view != _webFrame && view != [_webFrame documentView])
        return;

    if(view == [_webFrame documentView])
    {
        //LOG(@"frame changed: %@ → %@", NSStringFromRect(lastFrame), NSStringFromRect([view frame]));
        if(NSMaxY(lastVisibleRect) >= NSMaxY(lastFrame))
        {
            //LOG(@"scroll to bottom");
            [self scrollViewToBottom:view];
            lastVisibleRect = [view visibleRect];
        }
        lastFrame = [view frame];
    }

    if(view == _webFrame)
    {
        //LOG(@"visible rect changed: %@ → %@", NSStringFromRect(lastVisibleRect), NSStringFromRect([[webFrame documentView] frame]));
        if(NSMaxY(lastVisibleRect) >= NSMaxY(lastFrame))
        {
            //LOG(@"scroll to bottom");
            [self scrollViewToBottom:[_webFrame documentView]];
        }
    }

    [_scroller updateScroller];
}

@end
