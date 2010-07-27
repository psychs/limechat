// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "TreeView.h"


@implementation TreeView

@synthesize keyDelegate;

- (int)countSelectedRows
{
	return [[self selectedRowIndexes] count];
}

- (void)selectItemAtIndex:(int)index
{
	[self selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
	[self scrollRowToVisible:index];
}

- (NSMenu*)menuForEvent:(NSEvent *)e
{
	NSPoint p = [self convertPoint:[e locationInWindow] fromView:nil];
	int i = [self rowAtPoint:p];
	if (i >= 0) {
		[self selectItemAtIndex:i];
	}
	return [self menu];
}

- (void)setFont:(NSFont *)font
{
	for (NSTableColumn* column in [self tableColumns]) {
		[[column dataCell] setFont:font];
	}
	
	NSRect frame = self.frame;
	frame.size.height = 1e+37;
	CGFloat height = [[[[self tableColumns] objectAtIndex:0] dataCell] cellSizeForBounds:frame].height;
	[self setRowHeight:ceil(height)];
	[self setNeedsDisplay:YES];
}

- (NSFont*)font
{
	return [[[[self tableColumns] objectAtIndex:0] dataCell] font];
}

- (void)keyDown:(NSEvent *)e
{
	if (keyDelegate) {
		switch ([e keyCode]) {
			case 123 ... 126:
			case 116:
			case 121:
				break;
			default:
				if ([keyDelegate respondsToSelector:@selector(treeViewKeyDown:)]) {
					[keyDelegate treeViewKeyDown:e];
				}
				break;
		}
	}
	
	[super keyDown:e];
}

@end
