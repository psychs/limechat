#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>


@interface LogView : WebView
{
	id keyDelegate;
	id resizeDelegate;
}

@property (nonatomic, assign) id keyDelegate;
@property (nonatomic, assign) id resizeDelegate;

- (void)clearSel;
- (NSString*)selection;

@end


@interface NSObject (LogViewDelegate)
- (void)logViewKeyDown:(NSEvent*)e;
- (void)logViewWillResize;
- (void)logViewDidResize;
@end
