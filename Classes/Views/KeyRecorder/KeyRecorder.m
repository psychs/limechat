// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "KeyRecorder.h"
#import "KeyCodeTranslator.h"


#define BUTTON_SIZE     14
#define NUM(n)          [NSNumber numberWithInt:n]


static NSString* COMMAND = @"⌘";
static NSString* SHIFT   = @"⇧";
static NSString* ALT     = @"⌥";
static NSString* CTRL    = @"⌃";

static NSDictionary* specialKeyMap;
static NSArray* padKeyArray;

static NSDictionary* placeholderAttribute;
static NSDictionary* normalAttribute;

static NSImage* eraseButtonImage;
static NSImage* eraseButtonPushedImage;


@interface KeyRecorder (Private)
- (void)clearKey;
- (void)stopRecording;
- (NSString*)transformKeyCodeToString:(unsigned int)k;
- (NSString*)stringForCurrentKey;
- (NSBezierPath*)borderPath;
- (NSRect)eraseButtonFrame;
@end


@implementation KeyRecorder

@synthesize delegate, keyCode, modifierFlags;


+ (Class)cellClass
{
    return [KeyRecorderCell class];
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)setKeyCode:(int)value
{
    if (keyCode != value) {
        keyCode = value;
        [self setNeedsDisplay];
    }
}

- (void)setModifierFlags:(NSUInteger)value
{
    if (modifierFlags != value) {
        modifierFlags = value;
        [self setNeedsDisplay];
    }
}

- (BOOL)valid
{
    return keyCode != 0;
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (BOOL)resignFirstResponder
{
    recording = NO;
    [self setNeedsDisplay];
    return YES;
}

- (void)mouseDown:(NSEvent*)e
{
    [self.window makeFirstResponder:self];
    
    NSPoint pt = [self convertPoint:[e locationInWindow] fromView:nil];
    
    if (!recording && NSPointInRect(pt, [self eraseButtonFrame])) {
        eraseButtonPushed = YES;
        eraseButtonHighlighted = YES;
    }
    else {
        recording = !recording;
    }
    
    [self setNeedsDisplay];
}

- (void)mouseDragged:(NSEvent*)e
{
    if (eraseButtonPushed) {
        NSPoint pt = [self convertPoint:[e locationInWindow] fromView:nil];
        eraseButtonHighlighted = NSPointInRect(pt, [self eraseButtonFrame]);
        [self setNeedsDisplay];
    }
}

- (void)mouseUp:(NSEvent*)e
{
    if (eraseButtonPushed) {
        NSPoint pt = [self convertPoint:[e locationInWindow] fromView:nil];
        if (NSPointInRect(pt, [self eraseButtonFrame])) {
            [self clearKey];
        }
    }
    
    eraseButtonPushed = NO;
    eraseButtonHighlighted = NO;
    [self setNeedsDisplay];
}

- (void)rightMouseDown:(NSEvent*)e
{
}

- (void)rightMouseDragged:(NSEvent*)e
{
}

- (void)rightMouseUp:(NSEvent*)e
{
}

- (void)otherMouseDown:(NSEvent*)e
{
}

- (void)otherMouseDragged:(NSEvent*)e
{
}

- (void)otherMouseUp:(NSEvent*)e
{
}

- (void)keyDown:(NSEvent*)e
{
    if (!recording || self.window.firstResponder != self) return;
    
    int k = [e keyCode];
    NSUInteger m = [e modifierFlags];
    BOOL ctrl  = (m & NSControlKeyMask) != 0;
    BOOL alt   = (m & NSAlternateKeyMask) != 0;
    BOOL cmd   = (m & NSCommandKeyMask) != 0;
    
    //LOG(@"keyDown: %d %d", k, m);
    
    // all keys
    switch (k) {
        case 51:	// backspace
        case 117:	// delete
            [self clearKey];
            return;
    }
    
    if (!ctrl && !alt && !cmd) {
        // no mods or shift
        switch (k) {
            case 36:	// return
            case 48:	// tab
            case 49:	// space
            case 53:	// esc
            case 76:	// enter
                [self stopRecording];
                return;
        }
    }
}

- (void)keyUp:(NSEvent*)e
{
}

- (void)interpretKeyEvents:(NSArray*)eventAry
{
}

- (BOOL)performKeyEquivalent:(NSEvent*)e
{
    if (!recording || self.window.firstResponder != self) return NO;
    
    int k = [e keyCode];
    NSUInteger m = [e modifierFlags];
    BOOL ctrl = (m & NSControlKeyMask) != 0;
    BOOL shift = (m & NSShiftKeyMask) != 0;
    BOOL alt = (m & NSAlternateKeyMask) != 0;
    BOOL cmd = (m & NSCommandKeyMask) != 0;
    
    //LOG(@"performKeyEquivalent: %d %d", k, m);
    
    // all keys
    switch (k) {
        case 51:	// backspace
        case 117:	// delete
            [self clearKey];
            return YES;
    }
    
    if (!ctrl && !alt && !cmd) {
        // no mods or shift
        switch (k) {
            case 36:	// return
            case 48:	// tab
            case 49:	// space
            case 53:	// esc
            case 76:	// enter
                [self stopRecording];
                return NO;
            default:
            {
                NSString* s = specialKeyMap[NUM(k)];
                if (!s) {
                    return YES;
                }
                break;
            }
        }
    }
    else if (!ctrl && !shift && !alt && cmd) {
        // cmd
        if (![padKeyArray containsObject:NUM(k)]) {
            return NO;
        }
    }
    
    int prevKeyCode = keyCode;
    NSUInteger prevModifierFlags = modifierFlags;
    
    recording = NO;
    keyCode = k;
    modifierFlags = m;
    [self setNeedsDisplay];
    
    if (keyCode != prevKeyCode || modifierFlags != prevModifierFlags) {
        if ([delegate respondsToSelector:@selector(keyRecorderDidChangeKey:)]) {
            [delegate keyRecorderDidChangeKey:self];
        }
    }
    
    return YES;
}


- (void)clearKey
{
    int prevKeyCode = keyCode;
    NSUInteger prevModifierFlags = modifierFlags;
    
    recording = NO;
    keyCode = 0;
    modifierFlags = 0;
    [self setNeedsDisplay];
    
    if (keyCode != prevKeyCode && modifierFlags != prevModifierFlags) {
        if ([delegate respondsToSelector:@selector(keyRecorderDidChangeKey:)]) {
            [delegate keyRecorderDidChangeKey:self];
        }
    }
}

- (void)stopRecording
{
    recording = NO;
    [self setNeedsDisplay];
}

- (NSString*)transformKeyCodeToString:(unsigned int)k
{
    NSString* name = specialKeyMap[NUM(k)];
    if (name) return name;
    
    NSString* s = [[KeyCodeTranslator sharedInstance] translateKeyCode:k];
    if (!s) return nil;
    
    BOOL isPadKey = [padKeyArray containsObject:NUM(k)];
    NSString* keyString = [s uppercaseString];
    if (isPadKey) {
        keyString = [NSString stringWithFormat:@"#%@", keyString];
    }
    return keyString;
}

- (NSString*)stringForCurrentKey
{
    if (keyCode == 0) return nil;
    
    NSString* keyName = [self transformKeyCodeToString:keyCode];
    if (!keyName) {
        return nil;
    }
    
    NSMutableString* s = [NSMutableString string];
    
    BOOL ctrl  = (modifierFlags & NSControlKeyMask) != 0;
    BOOL alt   = (modifierFlags & NSAlternateKeyMask) != 0;
    BOOL shift = (modifierFlags & NSShiftKeyMask) != 0;
    BOOL cmd   = (modifierFlags & NSCommandKeyMask) != 0;
    
    if (ctrl)  [s appendString:CTRL];
    if (alt)   [s appendString:ALT];
    if (shift) [s appendString:SHIFT];
    if (cmd)   [s appendString:COMMAND];
    
    [s appendString:keyName];
    
    return s;
}

- (NSBezierPath*)borderPath
{
    NSRect r = self.bounds;
    r = NSInsetRect(r, 0.5, 0.5);
    CGFloat radius = r.size.height / 2;
    return [NSBezierPath bezierPathWithRoundedRect:r xRadius:radius yRadius:radius];
}

- (NSRect)eraseButtonFrame
{
    NSRect r = self.bounds;
    
    CGFloat deltaY = r.size.height - BUTTON_SIZE;
    
    r.origin.x += r.size.width - BUTTON_SIZE - 4;
    r.origin.y += deltaY/2;
    r.size.width = BUTTON_SIZE;
    r.size.height = BUTTON_SIZE;
    
    return r;
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSRect r = self.bounds;
    
    //
    // border
    //
    NSBezierPath* path = [self borderPath];
    [path setLineWidth:1];
    [[NSColor whiteColor] set];
    [path fill];
    [[NSColor colorWithCalibratedWhite:0.6 alpha:1] set];
    [path stroke];
    
    //
    // content
    //
    NSString* s = nil;
    NSDictionary* attr = nil;
    NSImage* button = nil;
    
    if (recording) {
        s = @"Type shortcut...";
        attr = placeholderAttribute;
    }
    else if (keyCode) {
        s = [self stringForCurrentKey];
        attr = normalAttribute;
    }
    
    if (!s) {
        s = @"Click to set shortcut";
        attr = placeholderAttribute;
    }
    if (keyCode && !recording) {
        button = eraseButtonHighlighted ? eraseButtonPushedImage : eraseButtonImage;
    }
    
    NSAttributedString* as = [[[NSAttributedString alloc] initWithString:s attributes:attr] autorelease];
    r = NSInsetRect(r, 10, 1);
    r.origin.y -= 2;
    [as drawInRect:r];
    
    if (button) {
        NSRect buttonRect = [self eraseButtonFrame];
        NSRect sourceRect = NSMakeRect(0, 0, BUTTON_SIZE, BUTTON_SIZE);
        [button drawInRect:buttonRect fromRect:sourceRect operation:NSCompositeSourceOver fraction:1];
    }
    
    //
    // focus ring
    //
    [super drawRect:dirtyRect];
}



+ (void)load
{
    if (self != [KeyRecorder class]) return;
    
    NSAutoreleasePool* pool = [NSAutoreleasePool new];

    specialKeyMap = @{
        @36: @"↩",
        @48: @"⇥",
        @49: @"Space",
        @51: @"⌫",
        @53: @"⎋",
        @64: @"F17",
        @71: @"Clear",
        @76: @"⌅",
        @79: @"F18",
        @80: @"F19",
        @96: @"F5",
        @97: @"F6",
        @98: @"F7",
        @99: @"F3",
        @100: @"F8",
        @101: @"F9",
        @103: @"F11",
        @105: @"F13",
        @106: @"F16",
        @107: @"F14",
        @109: @"F10",
        @111: @"F12",
        @113: @"F15",
        @114: @"Help",
        @115: @"↖",
        @116: @"⇞",
        @117: @"⌦",
        @118: @"F4",
        @119: @"↘",
        @120: @"F2",
        @121: @"⇟",
        @122: @"F1",
        @123: @"←",
        @124: @"→",
        @125: @"↓",
        @126: @"↑",
    };
    [specialKeyMap retain];
    
    padKeyArray = @[@65, // ,
                    @67, // *
                    @69, // +
                    @75, // /
                    @78, // -
                    @81, // =
                    @82, // 0
                    @83, // 1
                    @84, // 2
                    @85, // 3
                    @86, // 4
                    @87, // 5
                    @88, // 6
                    @89, // 7
                    @91, // 8
                    @92, // 9
                   ];
    [padKeyArray retain];
    
    NSMutableParagraphStyle* ps = [[NSMutableParagraphStyle new] autorelease];
    [ps setAlignment:NSCenterTextAlignment];
    placeholderAttribute = @{
        NSFontAttributeName: [NSFont systemFontOfSize:12],
        NSForegroundColorAttributeName: [NSColor colorWithCalibratedWhite:0.4 alpha:1],
        NSParagraphStyleAttributeName: ps,
    };
    [placeholderAttribute retain];
    
    normalAttribute = @{
        NSFontAttributeName: [NSFont systemFontOfSize:12],
        NSForegroundColorAttributeName: [NSColor blackColor],
        NSParagraphStyleAttributeName: ps,
    };
    [normalAttribute retain];
    
    eraseButtonImage = [[NSImage imageNamed:@"keyrecorder_erase.png"] retain];
    eraseButtonPushedImage = [[NSImage imageNamed:@"keyrecorder_erase_pushed.png"] retain];
    
    [pool release];
}

@end
