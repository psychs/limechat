// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "KeyCodeTranslator.h"


#define MAX_LEN     4


@implementation KeyCodeTranslator
{
    TISInputSourceRef _layout;
    const UCKeyboardLayout* _layoutData;
}

- (id)initWithKeyboardLayout:(TISInputSourceRef)aLayout
{
    self = [super init];
    if (self) {
        _layout = aLayout;
        CFDataRef data = TISGetInputSourceProperty(_layout , kTISPropertyUnicodeKeyLayoutData);
        _layoutData = (const UCKeyboardLayout*)CFDataGetBytePtr(data);
    }
    return self;
}

- (void)dealloc
{
    if (_layout) CFRelease(_layout);
}

+ (id)sharedInstance
{
    static KeyCodeTranslator* instance = nil;
    TISInputSourceRef currentLayout = TISCopyCurrentKeyboardLayoutInputSource();

    if (!instance) {
        instance = [[KeyCodeTranslator alloc] initWithKeyboardLayout:currentLayout];
    }
    else if ([instance keyboardLayout] != currentLayout) {
        instance = [[KeyCodeTranslator alloc] initWithKeyboardLayout:currentLayout];
    }
    return instance;
}

- (TISInputSourceRef)keyboardLayout
{
    return _layout;
}

- (NSString *)translateKeyCode:(short)keyCode
{
    UniCharCount len;
    UniChar str[MAX_LEN];
    UInt32 deadKeyState;

    UCKeyTranslate(_layoutData, keyCode, kUCKeyActionDisplay, 0, LMGetKbdType(), kUCKeyTranslateNoDeadKeysBit, &deadKeyState, MAX_LEN, &len, str);
    return [NSString stringWithCharacters:str length:1];
}

@end
