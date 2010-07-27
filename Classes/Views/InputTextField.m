// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "InputTextField.h"


@implementation InputTextField

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
	[[self backgroundColor] set];
	NSFrameRectWithWidth([self bounds], 3);
}

- (void)awakeFromNib
{
	[self registerForDraggedTypes:[NSArray arrayWithObject:NSStringPboardType]];
}

- (NSString*)draggedString:(id <NSDraggingInfo>)sender
{
	return [[sender draggingPasteboard] stringForType:NSStringPboardType];
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	NSString* s = [self draggedString:sender];
	if (s.length) {
		return NSDragOperationCopy;
	}
	else {
		return NSDragOperationNone;
	}
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
	return NSDragOperationCopy;
}

- (void)draggingEnded:(id <NSDraggingInfo>)sender
{
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
	NSString* s = [self draggedString:sender];
	return s.length > 0;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	NSString* s = [self draggedString:sender];
	if (s.length) {
		[self setStringValue:[[self stringValue] stringByAppendingString:s]];
		return YES;
	}
	return NO;
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
}

@end
