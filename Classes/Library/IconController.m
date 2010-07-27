// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "IconController.h"


@implementation IconController

- (void)setHighlight:(BOOL)aHighlight newTalk:(BOOL)aNewTalk
{
	if (highlight == aHighlight && newTalk == aNewTalk) return;
	highlight = aHighlight;
	newTalk = aNewTalk;
	
	NSImage* icon = [NSImage imageNamed:@"NSApplicationIcon"];
	if (highlight || newTalk) {
		icon = [[icon copy] autorelease];
		[icon lockFocus];
		
		if (highlight) {
			static NSImage* highlightBadge = nil;
			if (!highlightBadge) {
				highlightBadge = [[NSImage imageNamed:@"redstar"] retain];
			}
			
			NSSize iconSize = icon.size;
			NSSize size = highlightBadge.size;
			int w = size.width;
			int h = size.height;
			int x = iconSize.width - w;
			int y = iconSize.height - h;
			[highlightBadge compositeToPoint:NSMakePoint(x, y) operation:NSCompositeSourceOver];
		}
		else if (newTalk) {
			static NSImage* newTalkBadge = nil;
			if (!newTalkBadge) {
				newTalkBadge = [[NSImage imageNamed:@"bluestar"] retain];
			}
			
			NSSize iconSize = icon.size;
			NSSize size = newTalkBadge.size;
			int w = size.width;
			int h = size.height;
			int x = iconSize.width - w;
			int y = iconSize.height - h;
			[newTalkBadge compositeToPoint:NSMakePoint(x, y) operation:NSCompositeSourceOver];
		}
		
		[icon unlockFocus];
	}
	
	[NSApp setApplicationIconImage:icon];
}
@end
