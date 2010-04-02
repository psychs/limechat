#import <Cocoa/Cocoa.h>
#import "ListView.h"


@interface MemberListView : ListView
{
	id dropDelegate;
	id theme;
	
	NSColor* bgColor;
	NSColor* topLineColor;
	NSColor* bottomLineColor;
	NSGradient* gradient;
}

@property (nonatomic, assign) id dropDelegate;
@property (nonatomic, retain) id theme;

@end


@interface NSObject (MemberListView)
- (void)memberListViewKeyDown:(NSEvent*)e;
- (void)memberListViewDropFiles:(NSArray*)files row:(NSNumber*)row;
@end
