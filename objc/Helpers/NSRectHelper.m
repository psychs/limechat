// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "NSRectHelper.h"


NSPoint NSRectCenter(NSRect rect)
{
	return NSMakePoint(rect.origin.x + rect.size.width/2, rect.origin.y + rect.size.height/2);
}
