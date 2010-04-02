#import <Cocoa/Cocoa.h>
#import "TreeView.h"


@interface ServerTreeView : TreeView
{
	id responderDelegate;
	id theme;
	
	NSColor* bgColor;
	NSColor* topLineColor;
	NSColor* bottomLineColor;
	NSGradient* gradient;
}

@property (nonatomic, assign) id responderDelegate;
@property (nonatomic, retain) id theme;

@end


@interface NSObject (ServerTreeViewDelegate)
- (void)serverTreeViewAcceptsFirstResponder;
@end
