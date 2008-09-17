// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "KeyRecorderBox.h"
#import "KeyRecorderBoxCell.h"
#import <Carbon/Carbon.h>
#import <CoreServices/CoreServices.h>

@interface KeyRecorderBox (Private)
- (void)initKeyMap;
- (NSString*)transformKeyCodeToString:(unsigned int)keyCode;
- (void)showCurrentKey;
@end

#define NUM(n) [NSNumber numberWithInt:n]

@implementation KeyRecorderBox

static NSString* COMMAND = @"⌘";
static NSString* SHIFT   = @"⇧";
static NSString* ALT     = @"⌥";
static NSString* CTRL    = @"⌃";

static NSDictionary* specialKeyMap;
static NSArray* padKeyArray;

+ (void)load
{
	NSAutoreleasePool* pool = [NSAutoreleasePool new];
	
	specialKeyMap = [NSDictionary dictionaryWithObjectsAndKeys:
		@"↩", NUM(36),
		@"⇥", NUM(48),
		@"Space", NUM(49),
		//@"⌫", NUM(51),
		//@"⎋", NUM(53),
		@"F17", NUM(64),
		@"Clear", NUM(71),
		@"⌅", NUM(76),
		@"F18", NUM(79),
		@"F19", NUM(80),
		@"F5", NUM(96),
		@"F6", NUM(97),
		@"F7", NUM(98),
		@"F3", NUM(99),
		@"F8", NUM(100),
		@"F9", NUM(101),
		@"F11", NUM(103),
		@"F13", NUM(105),
		@"F16", NUM(106),
		@"F14", NUM(107),
		@"F10", NUM(109),
		@"F12", NUM(111),
		@"F15", NUM(113),
		@"Help", NUM(114),
		@"↖", NUM(115),
		@"⇞", NUM(116),
		//@"⌦", NUM(117),
		@"F4", NUM(118),
		@"↘", NUM(119),
		@"F2", NUM(120),
		@"⇟", NUM(121),
		@"F1", NUM(122),
		@"←", NUM(123),
		@"→", NUM(124),
		@"↓", NUM(125),
		@"↑", NUM(126),
		nil
	];
	[specialKeyMap retain];
	
	padKeyArray = [NSArray arrayWithObjects:
	   NUM(65), // ,
	   NUM(67), // *
	   NUM(69), // +
	   NUM(75), // /
	   NUM(78), // -
	   NUM(81), // =
	   NUM(82), // 0
	   NUM(83), // 1
	   NUM(84), // 2
	   NUM(85), // 3
	   NUM(86), // 4
	   NUM(87), // 5
	   NUM(88), // 6
	   NUM(89), // 7
	   NUM(91), // 8
	   NUM(92), // 9
	   nil
	];
	[padKeyArray retain];
	
	[pool release];
}

+ (Class)cellClass
{
	return [KeyRecorderBoxCell class];
}

- (id)initWithFrame:(NSRect)rect
{
	self = [super initWithFrame:rect];
	if (self) {
		[self setFocusRingType:NSFocusRingTypeExterior];
	}
	return self;
}

- (void)dealloc
{
	[super dealloc];
}

- (BOOL)valid { return valid; }
- (int)keyCode { return currentKeyCode; }
- (int)modifierFlags { return currentModifierFlags; }

- (void)setKeyCode:(int)aKeyCode modifierFlags:(int)aModifierFlags
{
	currentKeyCode = aKeyCode;
	currentModifierFlags = aModifierFlags;
	
	valid = YES;
	[self showCurrentKey];
}

- (void)clearKey
{
	valid = NO;
	[[self cell] setTitle:@""];
}

- (void)mouseDown:(NSEvent*)e
{
	[[self window] makeFirstResponder:self];
}

- (BOOL)performKeyEquivalent:(NSEvent*)e
{
	int k = currentKeyCode = [e keyCode];
	int m = currentModifierFlags = [e modifierFlags];
	
	//NSLog(@"performKeyEquivalent: %d %d", k, m);
	
	BOOL ctrl  = (m & NSControlKeyMask) != 0;
	BOOL shift = (m & NSShiftKeyMask) != 0;
	BOOL alt   = (m & NSAlternateKeyMask) != 0;
	BOOL cmd   = (m & NSCommandKeyMask) != 0;
	BOOL func  = (m & NSFunctionKeyMask) != 0;
	
	if (!ctrl && !shift && !alt && !cmd && !func) {
		// no mods
		switch (k) {
			case 36:	// return
			case 48:	// tab
			case 53:	// esc
			case 76:	// enter
				return NO;
			case 51:	// backspace
			case 117:	// delete
				[self clearKey];
				return YES;
			default:
			{
				NSString* s = [specialKeyMap objectForKey:NUM(k)];
				if (!s) {
					[self clearKey];
					return YES;
				}
				break;
			}
		}
	}
	else if (!ctrl && shift && !alt && !cmd && !func) {
		// shift
		switch (k) {
			case 48:	// tab
				return NO;
		}
	}
	else if (!ctrl && !shift && !alt && cmd && !func) {
		// cmd
		if (![padKeyArray containsObject:NUM(k)]) {
			return NO;
		}
	}
	
	valid = YES;
	[self showCurrentKey];
	return YES;
}

- (void)showCurrentKey
{
	NSString* keyName = [self transformKeyCodeToString:currentKeyCode];
	if (!keyName) {
		[self clearKey];
		return;
	}
	
	NSMutableString* s = [NSMutableString string];
	
	BOOL ctrl  = (currentModifierFlags & NSControlKeyMask) != 0;
	BOOL alt   = (currentModifierFlags & NSAlternateKeyMask) != 0;
	BOOL shift = (currentModifierFlags & NSShiftKeyMask) != 0;
	BOOL cmd   = (currentModifierFlags & NSCommandKeyMask) != 0;
	
	if (ctrl)  [s appendString:CTRL];
	if (alt)   [s appendString:ALT];
	if (shift) [s appendString:SHIFT];
	if (cmd)   [s appendString:COMMAND];
	
	[s appendString:keyName];
	
	[[self cell] setTitle:s];
}

- (NSString*)transformKeyCodeToString:(unsigned int)keyCode
{
	NSString* name = [specialKeyMap objectForKey:NUM(keyCode)];
	if (name) return name;
	
	BOOL isPadKey = [padKeyArray containsObject:NUM(keyCode)];
	
	KeyboardLayoutRef currentLayoutRef;
	KeyboardLayoutKind currentLayoutKind;
	OSStatus err;
	
	err = KLGetCurrentKeyboardLayout(&currentLayoutRef);
	if (err != noErr) return nil;
	
	err = KLGetKeyboardLayoutProperty(currentLayoutRef, kKLKind, (const void**)&currentLayoutKind);
	if (err != noErr) return nil;
	
	UInt32 keysDown = 0;
	
	if (currentLayoutKind == kKLKCHRKind) {
		Handle kchrHandle;
		err = KLGetKeyboardLayoutProperty(currentLayoutRef, kKLKCHRData, (const void**)&kchrHandle);
		if (err != noErr) return nil;
		
		UInt32 charCode = KeyTranslate(kchrHandle, keyCode, &keysDown);
		if (keysDown != 0) charCode = KeyTranslate(kchrHandle, keyCode, &keysDown);
		
		unsigned char c = charCode & 0xff;
		NSString* keyString = [[[[NSString alloc] initWithData:[NSData dataWithBytes:&c length:1] encoding:NSMacOSRomanStringEncoding] autorelease] uppercaseString];
		return (isPadKey ? [NSString stringWithFormat:@"#%@", keyString] : keyString);
	}
	else {
		UCKeyboardLayout *keyboardLayout = NULL;
		err = KLGetKeyboardLayoutProperty(currentLayoutRef, kKLuchrData, (const void**)&keyboardLayout);
		if (err != noErr) return nil;
		
		UniCharCount length = 4, realLength;
		UniChar chars[4];
		
		err = UCKeyTranslate(keyboardLayout, 
							 keyCode,
							 kUCKeyActionDisplay,
							 0,
							 LMGetKbdType(),
							 kUCKeyTranslateNoDeadKeysBit,
							 &keysDown,
							 length,
							 &realLength,
							 chars);
		
		if (err != noErr) return nil;
		
		NSString* keyString = [[NSString stringWithCharacters:chars length:1] uppercaseString];
		return (isPadKey ? [NSString stringWithFormat:@"#%@", keyString] : keyString);
	}
	
	return nil;    
}

@end
