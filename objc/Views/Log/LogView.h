// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>


@interface LogView : WebView
{
	id keyDelegate;
	id resizeDelegate;
}

@property (nonatomic, assign) id keyDelegate;
@property (nonatomic, assign) id resizeDelegate;

- (NSString*)contentString;

- (void)clearSelection;
- (BOOL)hasSelection;
- (NSString*)selection;

@end


@interface NSObject (LogViewDelegate)
- (void)logViewKeyDown:(NSEvent*)e;
- (void)logViewWillResize;
- (void)logViewDidResize;
@end
