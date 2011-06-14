// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "KeyEventHandler.h"


@implementation KeyEventHandler

@synthesize target;

- (id)init
{
	self = [super init];
	if (self) {
		codeHandlerMap = [NSMutableDictionary new];
		characterHandlerMap = [NSMutableDictionary new];
	}
	return self;
}

- (void)dealloc
{
	[codeHandlerMap release];
	[characterHandlerMap release];
	[super dealloc];
}

- (void)registerSelector:(SEL)selector key:(int)code modifiers:(NSUInteger)mods
{
	NSNumber* modsKey = [NSNumber numberWithUnsignedInteger:mods];
	NSMutableDictionary* map = [codeHandlerMap objectForKey:modsKey];
	if (!map) {
		map = [NSMutableDictionary dictionary];
		[codeHandlerMap setObject:map forKey:modsKey];
	}
	
	NSNumber* codeKey = [NSNumber numberWithInt:code];
	[map setObject:NSStringFromSelector(selector) forKey:codeKey];
}

- (void)registerSelector:(SEL)selector character:(UniChar)c modifiers:(NSUInteger)mods
{
	NSNumber* modsKey = [NSNumber numberWithUnsignedInteger:mods];
	NSMutableDictionary* map = [characterHandlerMap objectForKey:modsKey];
	if (!map) {
		map = [NSMutableDictionary dictionary];
		[characterHandlerMap setObject:map forKey:modsKey];
	}
	
	NSNumber* charKey = [NSNumber numberWithInt:c];
	[map setObject:NSStringFromSelector(selector) forKey:charKey];
}

- (void)registerSelector:(SEL)selector characters:(NSRange)characterRange modifiers:(NSUInteger)mods
{
	NSNumber* modsKey = [NSNumber numberWithUnsignedInteger:mods];
	NSMutableDictionary* map = [characterHandlerMap objectForKey:modsKey];
	if (!map) {
		map = [NSMutableDictionary dictionary];
		[characterHandlerMap setObject:map forKey:modsKey];
	}
	
	int from = characterRange.location;
	int to = NSMaxRange(characterRange);
	
	for (int i=from; i<to; ++i) {
		NSNumber* charKey = [NSNumber numberWithInt:i];
		[map setObject:NSStringFromSelector(selector) forKey:charKey];
	}
}

- (BOOL)processKeyEvent:(NSEvent*)e
{
	NSInputManager* im = [NSInputManager currentInputManager];
	if (im && [im markedRange].length > 0) return NO;
	
	NSUInteger m = [e modifierFlags];
	m &= NSShiftKeyMask | NSControlKeyMask | NSAlternateKeyMask | NSCommandKeyMask;
	NSNumber* modsKey = [NSNumber numberWithUnsignedInteger:m];
	
	NSMutableDictionary* codeMap = [codeHandlerMap objectForKey:modsKey];
	if (codeMap) {
		int k = [e keyCode];
		NSNumber* codeKey = [NSNumber numberWithInt:k];
		NSString* selectorName = [codeMap objectForKey:codeKey];
		if (selectorName) {
			[target performSelector:NSSelectorFromString(selectorName) withObject:e];
			return YES;
		}
	}
	
	NSMutableDictionary* characterMap = [characterHandlerMap objectForKey:modsKey];
	if (characterMap) {
		NSString* str = [[e charactersIgnoringModifiers] lowercaseString];
		if (str.length) {
			UniChar c = [str characterAtIndex:0];
			NSNumber* charKey = [NSNumber numberWithInt:c];
			NSString* selectorName = [characterMap objectForKey:charKey];
			if (selectorName) {
				[target performSelector:NSSelectorFromString(selectorName) withObject:e];
				return YES;
			}
		}
	}
	
	return NO;
}

@end
