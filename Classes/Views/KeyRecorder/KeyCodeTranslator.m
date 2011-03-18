// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "KeyCodeTranslator.h"


#define MAX_LEN	4


@implementation KeyCodeTranslator

- (id)initWithKeyboardLayout:(TISInputSourceRef)aLayout
{
	self = [super init];
	if (self) {
		layout = aLayout;
		CFDataRef data = TISGetInputSourceProperty(layout , kTISPropertyUnicodeKeyLayoutData);
		layoutData = (const UCKeyboardLayout*)CFDataGetBytePtr(data);
	}
	return self;
}

- (void)dealloc
{
	if (layout) CFRelease(layout);
	[super dealloc];
}

+ (id)sharedInstance
{
	static KeyCodeTranslator* instance = nil;
	TISInputSourceRef currentLayout = TISCopyCurrentKeyboardLayoutInputSource();

	if (!instance) {
		instance = [[KeyCodeTranslator alloc] initWithKeyboardLayout:currentLayout];
	}
	else if ([instance keyboardLayout] != currentLayout) {
		[instance release];
		instance = [[KeyCodeTranslator alloc] initWithKeyboardLayout:currentLayout];
	}
	return instance;
}

- (TISInputSourceRef)keyboardLayout
{
	return layout;
}

- (NSString *)translateKeyCode:(short)keyCode
{
	UniCharCount len;
	UniChar str[MAX_LEN];
	UInt32 deadKeyState;

	UCKeyTranslate(layoutData, keyCode, kUCKeyActionDisplay, 0, LMGetKbdType(), kUCKeyTranslateNoDeadKeysBit, &deadKeyState, MAX_LEN, &len, str);
	return [NSString stringWithCharacters:str length:1];
}

@end
