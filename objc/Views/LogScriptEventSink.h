#import <Cocoa/Cocoa.h>


@interface LogScriptEventSink : NSObject
{
	id owner;
	id policy;
	
	int x;
	int y;
	CFAbsoluteTime lastClickTime;
}

@property (nonatomic, assign) id owner;
@property (nonatomic, retain) id policy;


@end
