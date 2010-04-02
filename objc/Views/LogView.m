#import "LogView.h"


@implementation LogView

@synthesize keyDelegate;
@synthesize resizeDelegate;

- (void)keyDown:(NSEvent *)e
{
	if ([keyDelegate respondsToSelector:@selector(logViewKeyDown:)]) {
		[keyDelegate logViewKeyDown:e];
	}
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

- (void)clearSel
{
	[self setSelectedDOMRange:nil affinity:NSSelectionAffinityDownstream];
}

- (NSString*)selection
{
	DOMNode* sel = [[self selectedDOMRange] cloneContents];
	if (!sel) return nil;

	DOMNodeIterator* iter = [[[self selectedFrame] DOMDocument] createNodeIterator:sel whatToShow:DOM_SHOW_TEXT filter:nil expandEntityReferences:YES];
	NSMutableString* s = [NSMutableString string];
	DOMNode* node;
	while (node = [iter nextNode]) {
		[s appendString:[node nodeValue]];
	}
	
	if (s.length == 0) return nil;
	return s;
}

@end
