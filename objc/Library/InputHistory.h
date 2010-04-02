#import <Cocoa/Cocoa.h>


@interface InputHistory : NSObject
{
	NSMutableArray* buf;
	int pos;
}

- (void)add:(NSString*)s;
- (NSString*)up:(NSString*)s;
- (NSString*)down:(NSString*)s;

@end
