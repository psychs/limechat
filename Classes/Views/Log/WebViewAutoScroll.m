// Created by Allan Odgaard.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "WebViewAutoScroll.h"


@implementation WebViewAutoScroll
- (void)scrollViewToBottom:(NSView*)aView
{
	NSRect visibleRect = [aView visibleRect];
	visibleRect.origin.y = NSHeight([aView frame]) - NSHeight(visibleRect);
	[aView scrollRectToVisible:visibleRect];
}

- (void)dealloc
{
	self.webFrame = nil;
	[super dealloc];
}

- (void)setWebFrame:(WebFrameView*)aWebFrame
{
	if(aWebFrame == webFrame)
		return;
	
	//[webFrame release];
	//webFrame = [aWebFrame retain];
	webFrame = aWebFrame;
	
	if(webFrame)
	{
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(webViewDidChangeFrame:) name:NSViewFrameDidChangeNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(webViewDidChangeBounds:) name:NSViewBoundsDidChangeNotification object:nil];
		
		lastFrame = [[webFrame documentView] frame];
		lastVisibleRect = [[webFrame documentView] visibleRect];
	}
	else
	{
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:nil];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewBoundsDidChangeNotification object:nil];
	}
}

- (void)webViewDidChangeBounds:(NSNotification*)aNotification
{
	NSClipView* clipView = [[[webFrame documentView] enclosingScrollView] contentView];
	if(clipView != [aNotification object])
		return;
	
	//LOG(@"bounds changed: %@ → %@", NSStringFromRect(lastVisibleRect), NSStringFromRect([[clipView documentView] visibleRect]));
	lastVisibleRect = [[clipView documentView] visibleRect];
}

- (void)webViewDidChangeFrame:(NSNotification*)aNotification
{
	NSView* view = [aNotification object];
	if(view != webFrame && view != [webFrame documentView])
		return;
	
	if(view == [webFrame documentView])
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
	
	if(view == webFrame)
	{
		//LOG(@"visible rect changed: %@ → %@", NSStringFromRect(lastVisibleRect), NSStringFromRect([[webFrame documentView] frame]));
		if(NSMaxY(lastVisibleRect) >= NSMaxY(lastFrame))
		{
			//LOG(@"scroll to bottom");
			[self scrollViewToBottom:[webFrame documentView]];
		}
	}
}

@synthesize webFrame;
@end
