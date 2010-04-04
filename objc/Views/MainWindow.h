#import <Cocoa/Cocoa.h>
#import "KeyEventHandler.h"


@interface MainWindow : NSWindow
{
	KeyEventHandler* keyHandler;
}

- (void)setKeyHandlerTarget:(id)target;
- (void)registerKeyHandler:(SEL)selector key:(int)code modifiers:(NSUInteger)mods;
- (void)registerKeyHandler:(SEL)selector character:(UniChar)c modifiers:(NSUInteger)mods;

@end
