// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "DCCFileTransferCell.h"


#define FILENAME_HEIGHT         20
#define FILENAME_TOP_MARGIN     1
#define PROGRESS_BAR_HEIGHT     12
#define STATUS_HEIGHT           16
#define STATUS_TOP_MARGIN       1
#define RIGHT_MARGIN            10
#define ICON_SIZE               NSMakeSize(32, 32)


static char* UNITS[] = { "bytes", "KB", "MB", "GB", "TB" };


@implementation DCCFileTransferCell

- (id)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    DCCFileTransferCell* c = [[DCCFileTransferCell alloc] init];
    c.peerNick = _peerNick;
    c.processedSize = _processedSize;
    c.size = _size;
    c.speed = _speed;
    c.timeRemaining = _timeRemaining;
    c.status = _status;
    c.error = _error;
    c.progressBar = _progressBar;
    c.icon = _icon;
    c.sendingItem = _sendingItem;
    return c;
}

- (void)drawInteriorWithFrame:(NSRect)frame inView:(NSView*)view
{
    if (_icon) {
        CGFloat margin = (frame.size.height - ICON_SIZE.height) / 2;
        CGFloat x = frame.origin.x + margin;
        CGFloat y = frame.origin.y + margin;
        NSRect iconFrame = NSMakeRect(x, y, ICON_SIZE.width, ICON_SIZE.height);
        NSRect sourceRect = NSMakeRect(0, 0, _icon.size.width, _icon.size.height);
        [_icon drawInRect:iconFrame fromRect:sourceRect operation:NSCompositeSourceOver fraction:1 respectFlipped:YES hints:nil];
    }

    int offset = _progressBar ? 0 : (PROGRESS_BAR_HEIGHT / 3);

    NSString* fname = self.stringValue;

    NSRect fnameRect = frame;
    fnameRect.origin.x += fnameRect.size.height;
    fnameRect.origin.y += FILENAME_TOP_MARGIN + offset;
    fnameRect.size.width -= fnameRect.size.height + RIGHT_MARGIN;
    fnameRect.size.height = FILENAME_HEIGHT - FILENAME_TOP_MARGIN;

    NSColor* fnameColor;
    if (self.isHighlighted && [view.window isMainWindow] && [view.window firstResponder] == view) {
        fnameColor = [NSColor whiteColor];
    }
    else {
        fnameColor = [NSColor blackColor];
    }

    NSDictionary* fnameAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
                                [[self class] fileNameStyle], NSParagraphStyleAttributeName,
                                [NSFont systemFontOfSize:12], NSFontAttributeName,
                                fnameColor, NSForegroundColorAttributeName,
                                nil];

    [fname drawInRect:fnameRect withAttributes:fnameAttrs];

    if (_progressBar) {
        NSRect progressRect = frame;
        progressRect.origin.x += progressRect.size.height;
        progressRect.origin.y += FILENAME_HEIGHT;
        progressRect.size.width -= progressRect.size.height + RIGHT_MARGIN;
        progressRect.size.height = PROGRESS_BAR_HEIGHT;
        _progressBar.frame = progressRect;
    }

    NSRect statusRect = frame;
    statusRect.origin.x += statusRect.size.height;
    statusRect.origin.y += FILENAME_HEIGHT + PROGRESS_BAR_HEIGHT + STATUS_TOP_MARGIN - offset;
    statusRect.size.width -= statusRect.size.height + RIGHT_MARGIN;
    statusRect.size.height = STATUS_HEIGHT - STATUS_TOP_MARGIN;

    NSColor* statusColor;
    if (_status == DCC_ERROR) {
        statusColor = [NSColor redColor];
    }
    else if (_status == DCC_COMPLETE) {
        statusColor = [NSColor blueColor];
    }
    else if (self.isHighlighted && [view.window isMainWindow] && [view.window firstResponder] == view) {
        statusColor = [NSColor whiteColor];
    }
    else {
        statusColor = [NSColor grayColor];
    }

    NSDictionary* statusAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [[self class] statusStyle], NSParagraphStyleAttributeName,
                                 [NSFont systemFontOfSize:11], NSFontAttributeName,
                                 statusColor, NSForegroundColorAttributeName,
                                 nil];

    NSMutableString* statusStr = [NSMutableString string];

    if (_sendingItem) {
        [statusStr appendFormat:@"To %@    ", _peerNick];
    }
    else {
        [statusStr appendFormat:@"From %@    ", _peerNick];
    }

    switch (_status) {
        case DCC_INIT:
            [statusStr appendString:[self formatSize:_size]];
            break;
        case DCC_LISTENING:
            [statusStr appendFormat:@"%@  — Requesting", [self formatSize:_size]];
            break;
        case DCC_CONNECTING:
            [statusStr appendFormat:@"%@  — Connecting", [self formatSize:_size]];
            break;
        case DCC_SENDING:
        case DCC_RECEIVING:
            [statusStr appendFormat:@"%@ / %@ (%@/s)", [self formatSize:_processedSize], [self formatSize:_size], [self formatSize:_speed]];
            if (_timeRemaining) {
                [statusStr appendFormat:@"  — %@ remaining", [self formatTime:_timeRemaining]];
            }
            break;
        case DCC_STOP:
            [statusStr appendFormat:@"%@ / %@  — Stopped", [self formatSize:_processedSize], [self formatSize:_size]];
            break;
        case DCC_ERROR:
            [statusStr appendFormat:@"%@ / %@  — Error: %@", [self formatSize:_processedSize], [self formatSize:_size], _error];
            break;
        case DCC_COMPLETE:
            [statusStr appendFormat:@"%@  — Complete", [self formatSize:_size]];
            break;
    }

    [statusStr drawInRect:statusRect withAttributes:statusAttrs];
}

- (NSString*)formatSize:(long long)bytes
{
    int unit = 0;
    double data = 0;

    if (bytes > 0) {
        unit = floor(log2(bytes) / log2(1024));
        if (unit > 4) unit = 4;
        data = bytes / pow(1024, unit);
    }

    if (unit == 0 || data >= 10) {
        return [NSString stringWithFormat:@"%qi %s", (long long)data, UNITS[unit]];
    }
    else {
        return [NSString stringWithFormat:@"%1.1f %s", data, UNITS[unit]];
    }
}

- (NSString*)formatTime:(long long)sec
{
    long long min = sec / 60;
    sec %= 60;
    long long hour = min / 60;
    min %= 60;
    if (hour > 0) {
        return [NSString stringWithFormat:@"%d:%02d:%02d", (int)hour, (int)min, (int)sec];
    }
    else {
        return [NSString stringWithFormat:@"%02d:%02d", (int)min, (int)sec];
    }
}

+ (NSParagraphStyle*)fileNameStyle
{
    static NSMutableParagraphStyle* fileNameStyle = nil;
    if (!fileNameStyle) {
        fileNameStyle = [NSMutableParagraphStyle new];
        [fileNameStyle setAlignment:NSLeftTextAlignment];
        [fileNameStyle setLineBreakMode:NSLineBreakByTruncatingMiddle];
    }
    return fileNameStyle;
}

+ (NSParagraphStyle*)statusStyle
{
    static NSMutableParagraphStyle* statusStyle = nil;
    if (!statusStyle) {
        statusStyle = [NSMutableParagraphStyle new];
        [statusStyle setAlignment:NSLeftTextAlignment];
        [statusStyle setLineBreakMode:NSLineBreakByTruncatingTail];
    }
    return statusStyle;
}

@end
