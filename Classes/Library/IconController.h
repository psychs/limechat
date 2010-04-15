// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import <Cocoa/Cocoa.h>


@interface IconController : NSObject
{
	BOOL highlight;
	BOOL newTalk;
}

- (void)setHighlight:(BOOL)aHighlight newTalk:(BOOL)aNewTalk;

@end
