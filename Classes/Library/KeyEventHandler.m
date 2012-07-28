// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "KeyEventHandler.h"


@implementation KeyEventHandler
{
    __weak id target;
    NSMutableDictionary* codeHandlerMap;
    NSMutableDictionary* characterHandlerMap;
}

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
    NSMutableDictionary* map = codeHandlerMap[modsKey];
    if (!map) {
        map = [NSMutableDictionary dictionary];
        codeHandlerMap[modsKey] = map;
    }
    
    NSNumber* codeKey = [NSNumber numberWithInt:code];
    map[codeKey] = NSStringFromSelector(selector);
}

- (void)registerSelector:(SEL)selector character:(UniChar)c modifiers:(NSUInteger)mods
{
    NSNumber* modsKey = [NSNumber numberWithUnsignedInteger:mods];
    NSMutableDictionary* map = characterHandlerMap[modsKey];
    if (!map) {
        map = [NSMutableDictionary dictionary];
        characterHandlerMap[modsKey] = map;
    }
    
    NSNumber* charKey = [NSNumber numberWithInt:c];
    map[charKey] = NSStringFromSelector(selector);
}

- (void)registerSelector:(SEL)selector characters:(NSRange)characterRange modifiers:(NSUInteger)mods
{
    NSNumber* modsKey = [NSNumber numberWithUnsignedInteger:mods];
    NSMutableDictionary* map = characterHandlerMap[modsKey];
    if (!map) {
        map = [NSMutableDictionary dictionary];
        characterHandlerMap[modsKey] = map;
    }
    
    int from = characterRange.location;
    int to = NSMaxRange(characterRange);
    
    for (int i=from; i<to; ++i) {
        NSNumber* charKey = [NSNumber numberWithInt:i];
        map[charKey] = NSStringFromSelector(selector);
    }
}

- (BOOL)processKeyEvent:(NSEvent*)e
{
    NSInputManager* im = [NSInputManager currentInputManager];
    if (im && [im markedRange].length > 0) return NO;
    
    NSUInteger m = [e modifierFlags];
    m &= NSShiftKeyMask | NSControlKeyMask | NSAlternateKeyMask | NSCommandKeyMask;
    NSNumber* modsKey = [NSNumber numberWithUnsignedInteger:m];
    
    NSMutableDictionary* codeMap = codeHandlerMap[modsKey];
    if (codeMap) {
        int k = [e keyCode];
        NSNumber* codeKey = [NSNumber numberWithInt:k];
        NSString* selectorName = codeMap[codeKey];
        if (selectorName) {
            [target performSelector:NSSelectorFromString(selectorName) withObject:e];
            return YES;
        }
    }
    
    NSMutableDictionary* characterMap = characterHandlerMap[modsKey];
    if (characterMap) {
        NSString* str = [[e charactersIgnoringModifiers] lowercaseString];
        if (str.length) {
            UniChar c = [str characterAtIndex:0];
            NSNumber* charKey = [NSNumber numberWithInt:c];
            NSString* selectorName = characterMap[charKey];
            if (selectorName) {
                [target performSelector:NSSelectorFromString(selectorName) withObject:e];
                return YES;
            }
        }
    }
    
    return NO;
}

@end
