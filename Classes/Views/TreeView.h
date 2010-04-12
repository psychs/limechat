// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import <Cocoa/Cocoa.h>


@interface TreeView : NSOutlineView
{
	id keyDelegate;
}

@property (nonatomic, assign) id keyDelegate;

- (int)countSelectedRows;
- (void)select:(int)index;

@end


@interface NSObject (TreeViewDelegate)
- (void)treeViewKeyDown:(NSEvent*)e;
@end
