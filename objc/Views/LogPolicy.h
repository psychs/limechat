#import <Cocoa/Cocoa.h>


@interface ALogPolicy : NSObject
{
	id owner;
	NSMenu* menu;
	NSMenu* urlMenu;
	NSMenu* addrMenu;
	NSMenu* memberMenu;
	NSMenu* chanMenu;
	
	NSString* url;
	NSString* addr;
	NSString* nick;
	NSString* chan;
}
@end
