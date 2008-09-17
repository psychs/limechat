// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.
#import "KeyRecorderBoxCell.h"

@implementation KeyRecorderBoxCell

- (id)init
{
	self = [super init];
	if (self) {
		[self setBezeled:YES];
		[self setBezelStyle:NSShadowlessSquareBezelStyle];
		[self setTitle:@""];
	}
	return self;
}

- (void)performClick:(id)sender
{
}

@end
