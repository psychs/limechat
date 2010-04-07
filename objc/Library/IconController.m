// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

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
