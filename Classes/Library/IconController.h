// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the new BSD license.

#import <Cocoa/Cocoa.h>


@interface IconController : NSObject
{
	BOOL highlight;
	BOOL newTalk;
}

- (void)setHighlight:(BOOL)aHighlight newTalk:(BOOL)aNewTalk;

@end
