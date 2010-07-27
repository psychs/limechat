// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

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
