// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Cocoa/Cocoa.h>


@interface TreeView : NSOutlineView
{
	id keyDelegate;
}

@property (nonatomic, assign) id keyDelegate;

- (int)countSelectedRows;
- (void)selectItemAtIndex:(int)index;

@end


@interface NSObject (TreeViewDelegate)
- (void)treeViewKeyDown:(NSEvent*)e;
@end
