// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "DCCFileTransferCell.h"


#define FILENAME_HEIGHT			20
#define FILENAME_TOP_MARGIN		1
#define PROGRESS_BAR_HEIGHT		12
#define STATUS_HEIGHT			16
#define STATUS_TOP_MARGIN		1
#define RIGHT_MARGIN			10
#define ICON_SIZE				NSMakeSize(32, 32)


static NSMutableParagraphStyle* fileNameStyle;
static NSMutableParagraphStyle* statusStyle;


@interface DCCFileTransferCell (Private)
- (NSString*)formatSize:(long long)bytes;
- (NSString*)formatTime:(long long)sec;
@end


@implementation DCCFileTransferCell

@synthesize peerNick;
@synthesize processedSize;
@synthesize size;
@synthesize speed;
@synthesize timeRemaining;
@synthesize status;
@synthesize error;
@synthesize progressBar;
@synthesize icon;
@synthesize sendingItem;

- (id)init
{
	self = [super init];
	if (self) {
	}
	return self;
}

- (void)dealloc
{
	[peerNick release];
	[error release];
	[progressBar release];
	[icon release];
	[super dealloc];
}

- (id)copyWithZone:(NSZone *)zone
{
	DCCFileTransferCell* c = [[DCCFileTransferCell allocWithZone:zone] init];
	c.peerNick = peerNick;
	c.processedSize = processedSize;
	c.size = size;
	c.speed = speed;
	c.timeRemaining = timeRemaining;
	c.status = status;
	c.error = error;
	c.progressBar = progressBar;
	c.icon = icon;
	c.sendingItem = sendingItem;
	return c;
}

- (void)drawInteriorWithFrame:(NSRect)frame inView:(NSView*)view
{
	if (icon) {
		int margin = (frame.size.height - ICON_SIZE.height) / 2;
		NSPoint p = frame.origin;
		p.x += margin;
		p.y += margin;
		if (view.isFlipped) p.y += ICON_SIZE.height;
		[icon setSize:ICON_SIZE];
		[icon compositeToPoint:p operation:NSCompositeSourceOver];
	}
	
	int offset = progressBar ? 0 : (PROGRESS_BAR_HEIGHT / 3);
	
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
								fileNameStyle, NSParagraphStyleAttributeName,
								[NSFont systemFontOfSize:12], NSFontAttributeName,
								fnameColor, NSForegroundColorAttributeName,
								nil];
	
	[fname drawInRect:fnameRect withAttributes:fnameAttrs];
	
	if (progressBar) {
		NSRect progressRect = frame;
		progressRect.origin.x += progressRect.size.height;
		progressRect.origin.y += FILENAME_HEIGHT;
		progressRect.size.width -= progressRect.size.height + RIGHT_MARGIN;
		progressRect.size.height = PROGRESS_BAR_HEIGHT;
		progressBar.frame = progressRect;
	}
	
	NSRect statusRect = frame;
	statusRect.origin.x += statusRect.size.height;
	statusRect.origin.y += FILENAME_HEIGHT + PROGRESS_BAR_HEIGHT + STATUS_TOP_MARGIN - offset;
	statusRect.size.width -= statusRect.size.height + RIGHT_MARGIN;
	statusRect.size.height = STATUS_HEIGHT - STATUS_TOP_MARGIN;
	
	NSColor* statusColor;
	if (status == DCC_ERROR) {
		statusColor = [NSColor redColor];
	}
	else if (status == DCC_COMPLETE) {
		statusColor = [NSColor blueColor];
	}
	else if (self.isHighlighted && [view.window isMainWindow] && [view.window firstResponder] == view) {
		statusColor = [NSColor whiteColor];
	}
	else {
		statusColor = [NSColor grayColor];
	}
	
	NSDictionary* statusAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
								 statusStyle, NSParagraphStyleAttributeName,
								 [NSFont systemFontOfSize:11], NSFontAttributeName,
								 statusColor, NSForegroundColorAttributeName,
								 nil];
	
	NSMutableString* statusStr = [NSMutableString string];
	
	if (sendingItem) {
		[statusStr appendFormat:@"To %@    ", peerNick];
	}
	else {
		[statusStr appendFormat:@"From %@    ", peerNick];
	}
	
	switch (status) {
		case DCC_INIT:
			[statusStr appendString:[self formatSize:size]];
			break;
		case DCC_LISTENING:
			[statusStr appendFormat:@"%@  — Requesting", [self formatSize:size]];
			break;
		case DCC_CONNECTING:
			[statusStr appendFormat:@"%@  — Connecting", [self formatSize:size]];
			break;
		case DCC_SENDING:
		case DCC_RECEIVING:
			[statusStr appendFormat:@"%@ / %@ (%@/s)", [self formatSize:processedSize], [self formatSize:size], [self formatSize:speed]];
			if (timeRemaining) {
				[statusStr appendFormat:@"  — %@ remaining", [self formatTime:timeRemaining]];
			}
			break;
		case DCC_STOP:
			[statusStr appendFormat:@"%@ / %@  — Stopped", [self formatSize:processedSize], [self formatSize:size]];
			break;
		case DCC_ERROR:
			[statusStr appendFormat:@"%@ / %@  — Error: %@", [self formatSize:processedSize], [self formatSize:size], error];
			break;
		case DCC_COMPLETE:
			[statusStr appendFormat:@"%@  — Complete", [self formatSize:size]];
			break;
	}
	
	[statusStr drawInRect:statusRect withAttributes:statusAttrs];
}

static char* UNITS[] = { "bytes", "KB", "MB", "GB", "TB" };

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

+ (void)load
{
	if (self != [DCCFileTransferCell class]) return;
	
	NSAutoreleasePool* pool = [NSAutoreleasePool new];
	
	fileNameStyle = [NSMutableParagraphStyle new];
	[fileNameStyle setAlignment:NSLeftTextAlignment];
	[fileNameStyle setLineBreakMode:NSLineBreakByTruncatingMiddle];
	
	statusStyle = [NSMutableParagraphStyle new];
	[statusStyle setAlignment:NSLeftTextAlignment];
	[statusStyle setLineBreakMode:NSLineBreakByTruncatingTail];
	
	[pool drain];
}

@end
