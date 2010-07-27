// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Cocoa/Cocoa.h>
#import "KeyEventHandler.h"


@interface FieldEditorTextView : NSTextView
{
	id pasteDelegate;
	KeyEventHandler* keyHandler;
}

@property (nonatomic, assign) id pasteDelegate;

- (void)paste:(id)sender;

- (void)setKeyHandlerTarget:(id)target;
- (void)registerKeyHandler:(SEL)selector key:(int)code modifiers:(NSUInteger)mods;
- (void)registerKeyHandler:(SEL)selector character:(UniChar)c modifiers:(NSUInteger)mods;

@end


@interface NSObject (FieldEditorTextViewDelegate)
- (BOOL)fieldEditorTextViewPaste:(id)sender;
@end
