// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import <Cocoa/Cocoa.h>
#import "TreeView.h"
#import "OtherTheme.h"


@interface ServerTreeView : TreeView
{
	id responderDelegate;
	OtherTheme* theme;
	
	NSColor* bgColor;
	NSColor* topLineColor;
	NSColor* bottomLineColor;
	NSGradient* gradient;
}

@property (nonatomic, assign) id responderDelegate;
@property (nonatomic, retain) OtherTheme* theme;

- (void)themeChanged;

@end


@interface NSObject (ServerTreeViewDelegate)
- (void)serverTreeViewAcceptsFirstResponder;
@end
