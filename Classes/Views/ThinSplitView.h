// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import <Cocoa/Cocoa.h>


@interface ThinSplitView : NSSplitView
{
	int fixedViewIndex;
	int myDividerThickness;
	int position;
	BOOL inverted;
	BOOL hidden;
}

@property (nonatomic, assign) int fixedViewIndex;
@property (nonatomic, assign) int position;
@property (nonatomic, assign) BOOL inverted;
@property (nonatomic, assign) BOOL hidden;

@end
