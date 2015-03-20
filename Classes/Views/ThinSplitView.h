// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Cocoa/Cocoa.h>


@interface ThinSplitView : NSSplitView

@property (nonatomic) int fixedViewIndex;
@property (nonatomic) int position;
@property (nonatomic) BOOL inverted;
// This overrides super's `hidden` with a different meaning
// TODO: rename
@property (nonatomic) BOOL hidden;

@end
