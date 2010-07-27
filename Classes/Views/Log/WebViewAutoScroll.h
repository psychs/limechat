// Created by Allan Odgaard.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>


@interface WebViewAutoScroll : NSObject
{
	WebFrameView* webFrame;
	NSRect lastFrame, lastVisibleRect;
}
@property (nonatomic, assign) WebFrameView* webFrame;
@end
