// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "LogView.h"


@implementation LogView

@synthesize keyDelegate;
@synthesize resizeDelegate;

- (void)keyDown:(NSEvent *)e
{
	if (keyDelegate) {
		NSUInteger m = [e modifierFlags];
		BOOL ctrl = m & NSControlKeyMask;
		BOOL alt = m & NSAlternateKeyMask;
		BOOL cmd = m & NSCommandKeyMask;
		
		if (!(ctrl || alt || cmd)) {
			if ([keyDelegate respondsToSelector:@selector(logViewKeyDown:)]) {
				[keyDelegate logViewKeyDown:e];
			}
			return;
		}
	}
	
	[super keyDown:e];
}

- (void)setFrame:(NSRect)rect
{
	if (resizeDelegate && [resizeDelegate respondsToSelector:@selector(logViewWillResize)]) {
		[resizeDelegate logViewWillResize];
	}
	
	[super setFrame:rect];
	
	if (resizeDelegate && [resizeDelegate respondsToSelector:@selector(logViewDidResize)]) {
		[resizeDelegate logViewDidResize];
	}
}

- (BOOL)maintainsInactiveSelection
{
	return YES;
}

- (NSString*)contentString
{
	WebFrame* frame = [self mainFrame];
	if (!frame) return @"";
	DOMHTMLDocument* doc = (DOMHTMLDocument*)[frame DOMDocument];
	if (!doc) return @"";
	DOMElement* body = [doc body];
	if (!body) return @"";
	DOMHTMLElement* root = (DOMHTMLElement*)[body parentNode];
	if (!root) return @"";
	return [root outerHTML];
}

- (void)clearSelection
{
	[self setSelectedDOMRange:nil affinity:NSSelectionAffinityDownstream];
}

- (BOOL)hasSelection
{
	return [self selection].length > 0;
}

- (NSString*)selection
{
	DOMRange* range = [self selectedDOMRange];
	if (!range) return nil;
	return [range toString];
	
	/*
	DOMNode* sel = [[self selectedDOMRange] cloneContents];
	if (!sel) return nil;

	NSMutableString* s = [NSMutableString string];
	DOMNodeIterator* iter = [[[self selectedFrame] DOMDocument] createNodeIterator:sel whatToShow:DOM_SHOW_TEXT filter:nil expandEntityReferences:YES];
	DOMNode* node;
	
	while (node = [iter nextNode]) {
		[s appendString:[node nodeValue]];
	}
	
	if (s.length == 0) return nil;
	return s;
	 */
}

@end
