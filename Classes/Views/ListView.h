// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the new BSD license.

#import <Cocoa/Cocoa.h>


@interface ListView : NSTableView
{
	id keyDelegate;
	id textDelegate;
}

@property (nonatomic, assign) id keyDelegate;
@property (nonatomic, assign) id textDelegate;

- (int)countSelectedRows;
- (void)select:(int)index;
- (void)selectRows:(NSArray*)indices;
- (void)selectRows:(NSArray*)indices extendSelection:(BOOL)extend;

@end


@interface NSObject (ListViewDelegate)
- (void)listViewDelete;
- (void)listViewMoveUp;
- (void)listViewKeyDown:(NSEvent*)e;
@end
