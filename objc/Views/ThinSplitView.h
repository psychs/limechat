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
