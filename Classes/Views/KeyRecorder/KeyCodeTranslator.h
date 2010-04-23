// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the new BSD license.

#import <Foundation/Foundation.h>
#import <Carbon/Carbon.h>


@interface KeyCodeTranslator : NSObject
{
	TISInputSourceRef	layout;
	const UCKeyboardLayout* layoutData;
}

+ (id)sharedInstance;
- (TISInputSourceRef)keyboardLayout;

- (NSString *)translateKeyCode:(short)keyCode;

@end
