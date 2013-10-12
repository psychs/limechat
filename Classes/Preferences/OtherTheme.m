// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "OtherTheme.h"
#import "YAML.h"
#import "NSColorHelper.h"


@implementation OtherTheme
{
    NSDictionary* _content;
}

- (id)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)setFileName:(NSString *)value
{
    _fileName = value;
    [self reload];
}

- (void)reload
{
    _content = nil;

    _logNickFormat = nil;
    _logScrollerMarkColor = nil;

    _inputTextFont = nil;
    _inputTextBgColor = nil;
    _inputTextColor = nil;
    _inputTextSelColor = nil;

    _treeFont = nil;
    _treeBgColor = nil;
    _treeHighlightColor = nil;
    _treeNewTalkColor = nil;
    _treeUnreadColor = nil;

    _treeActiveColor = nil;
    _treeInactiveColor = nil;

    _treeSelActiveColor = nil;
    _treeSelInactiveColor = nil;
    _treeSelTopLineColor = nil;
    _treeSelBottomLineColor = nil;
    _treeSelTopColor = nil;
    _treeSelBottomColor = nil;

    _memberListFont = nil;
    _memberListBgColor = nil;
    _memberListColor = nil;
    _memberListOpColor = nil;

    _memberListSelColor = nil;
    _memberListSelTopLineColor = nil;
    _memberListSelBottomLineColor = nil;
    _memberListSelTopColor = nil;
    _memberListSelBottomColor = nil;


    //if (!fileName) return;

    NSData* data = [NSData dataWithContentsOfFile:_fileName];
    NSDictionary* dic = yaml_parse_raw_utf8(data.bytes, data.length);

    _content = dic;

    _logNickFormat = [self loadString:@"log-view", @"nickname-format", nil] ?: @"%n: ";
    _logScrollerMarkColor = [self loadColor:@"log-view", @"scroller-highlight-color", nil] ?: [NSColor magentaColor];

    _inputTextFont = [self loadFont:@"input-text"] ?: [NSFont systemFontOfSize:0];
    _inputTextBgColor = [self loadColor:@"input-text", @"background-color", nil] ?: [NSColor whiteColor];
    _inputTextColor = [self loadColor:@"input-text", @"color", nil] ?: [NSColor blackColor];
    _inputTextSelColor = [self loadColor:@"input-text", @"selected", @"background-color", nil] ?: [NSColor selectedTextBackgroundColor];

    _treeFont = [self loadFont:@"server-tree"] ?: [NSFont systemFontOfSize:0];
    _treeBgColor = [self loadColor:@"server-tree", @"background-color", nil] ?: DEVICE_RGB(229, 237, 247);
    _treeHighlightColor = [self loadColor:@"server-tree", @"highlight", @"color", nil] ?: [NSColor magentaColor];
    _treeNewTalkColor = [self loadColor:@"server-tree", @"newtalk", @"color", nil] ?: [NSColor redColor];
    _treeUnreadColor = [self loadColor:@"server-tree", @"unread", @"color", nil] ?: [NSColor blueColor];

    _treeActiveColor = [self loadColor:@"server-tree", @"normal", @"active", @"color", nil] ?: [NSColor blackColor];
    _treeInactiveColor = [self loadColor:@"server-tree", @"normal", @"inactive", @"color", nil] ?: [NSColor lightGrayColor];

    _treeSelActiveColor = [self loadColor:@"server-tree", @"selected", @"active", @"color", nil] ?: [NSColor blackColor];
    _treeSelInactiveColor = [self loadColor:@"server-tree", @"selected", @"inactive", @"color", nil] ?: [NSColor grayColor];
    _treeSelTopLineColor = [self loadColor:@"server-tree", @"selected", @"background", @"top-line-color", nil] ?: DEVICE_RGB(173, 187, 208);
    _treeSelBottomLineColor = [self loadColor:@"server-tree", @"selected", @"background", @"bottom-line-color", nil] ?: DEVICE_RGB(140, 152, 176);
    _treeSelTopColor = [self loadColor:@"server-tree", @"selected", @"background", @"top-color", nil] ?: DEVICE_RGB(173, 187, 208);
    _treeSelBottomColor = [self loadColor:@"server-tree", @"selected", @"background", @"bottom-color", nil] ?: DEVICE_RGB(152, 170, 196);

    _memberListFont = [self loadFont:@"member-list"] ?: [NSFont systemFontOfSize:[NSFont smallSystemFontSize]];
    _memberListBgColor = [self loadColor:@"member-list", @"background-color", nil] ?: [NSColor whiteColor];
    _memberListColor = [self loadColor:@"member-list", @"color", nil] ?: [NSColor blackColor];
    _memberListOpColor = [self loadColor:@"member-list", @"operator", @"color", nil] ?: [NSColor blackColor];
    _memberListSelColor = [self loadColor:@"member-list", @"selected", @"color", nil];
    _memberListSelTopLineColor = [self loadColor:@"member-list", @"selected", @"background", @"top-line-color", nil];
    _memberListSelBottomLineColor = [self loadColor:@"member-list", @"selected", @"background", @"bottom-line-color", nil];
    _memberListSelTopColor = [self loadColor:@"member-list", @"selected", @"background", @"top-color", nil];
    _memberListSelBottomColor = [self loadColor:@"member-list", @"selected", @"background", @"bottom-color", nil];

    _content = nil;
}

- (NSString*)loadString:(NSString*)key, ...
{
    va_list args;
    va_start(args, key);

    NSDictionary* dic = [_content objectForKey:key];
    while ([dic isKindOfClass:[NSDictionary class]] && (key = va_arg(args, id))) {
        dic = [dic objectForKey:key];
    }

    va_end(args);

    return (NSString*)dic;
}

- (NSColor*)loadColor:(NSString*)key, ...
{
    va_list args;
    va_start(args, key);

    NSDictionary* dic = [_content objectForKey:key];
    while ([dic isKindOfClass:[NSDictionary class]] && (key = va_arg(args, id))) {
        dic = [dic objectForKey:key];
    }

    va_end(args);

    NSString* s = (NSString*)dic;
    return [NSColor fromCSS:s];
}

- (NSFont*)loadFont:(NSString*)key
{
    NSDictionary* dic = [_content objectForKey:key];

    if (![dic isKindOfClass:[NSDictionary class]]) return nil;

    NSString* family = [dic objectForKey:@"font-family"];
    NSNumber* sizeNum = [dic objectForKey:@"font-size"];
    NSString* weight = [dic objectForKey:@"font-weight"];
    NSString* style = [dic objectForKey:@"font-style"];

    CGFloat size = 0;
    if (sizeNum) {
        size = [sizeNum floatValue];
    }
    else {
        size = [NSFont systemFontSize];
    }

    NSFont* font = nil;
    if (family) {
        font = [NSFont fontWithName:family size:size];
    }
    else {
        font = [NSFont systemFontOfSize:size];
    }

    if (!font) {
        font = [NSFont systemFontOfSize:0];
    }

    NSFontManager* fm = [NSFontManager sharedFontManager];
    if ([weight isEqualToString:@"bold"]) {
        NSFont* to = [fm convertFont:font toHaveTrait:NSBoldFontMask];
        if (to) {
            font = to;
        }
    }

    if ([style isEqualToString:@"italic"]) {
        NSFont* to = [fm convertFont:font toHaveTrait:NSItalicFontMask];
        if (to) {
            font = to;
        }
    }

    return font;
}

@end
