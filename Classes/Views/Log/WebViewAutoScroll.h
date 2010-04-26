// Created by Allan Odgaard.
// You can redistribute it and/or modify it under the new BSD license.

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>


@interface WebViewAutoScroll : NSObject
{
	WebFrameView* webFrame;
	NSRect lastFrame, lastVisibleRect;
}
@property (nonatomic, assign) WebFrameView* webFrame;
@end
