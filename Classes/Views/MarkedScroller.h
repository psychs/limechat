// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Cocoa/Cocoa.h>


@interface MarkedScroller : NSScroller
{
	id dataSource;
}

@property (nonatomic, assign) id dataSource;

@end


@interface NSObject (MarkedScrollerDataSource)
- (NSArray*)markedScrollerPositions:(MarkedScroller*)sender;
- (NSColor*)markedScrollerColor:(MarkedScroller*)sender;
@end
