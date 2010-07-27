// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Foundation/Foundation.h>
#import "ListView.h"


@interface ListDialog : NSWindowController
{
	id delegate;
	NSMutableArray* list;
	NSMutableArray* filteredList;
	int sortKey;
	NSComparisonResult sortOrder;
	
	IBOutlet ListView* table;
	IBOutlet NSSearchField* filterText;
	IBOutlet NSButton* updateButton;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, readonly) int sortKey;
@property (nonatomic, readonly) NSComparisonResult sortOrder;

- (void)start;
- (void)show;
- (void)close;
- (void)clear;

- (void)addChannel:(NSString*)channel count:(int)count topic:(NSString*)topic;

- (void)onClose:(id)sender;
- (void)onUpdate:(id)sender;
- (void)onJoin:(id)sender;
- (void)onSearchFieldChange:(id)sender;

@end


@interface NSObject (ListDialogDelegate)
- (void)listDialogOnUpdate:(ListDialog*)sender;
- (void)listDialogOnJoin:(ListDialog*)sender channel:(NSString*)channel;
- (void)listDialogWillClose:(ListDialog*)sender;
@end
