#import <Cocoa/Cocoa.h>


@interface MemberListViewCell : NSCell
{
	id member;
}

@property (nonatomic, retain) id member;

- (void)setup:(id)theme;
- (void)themeChanged;

@end
