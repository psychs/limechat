// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "SheetBase.h"


@implementation SheetBase

@synthesize delegate;
@synthesize window;

- (id)init
{
	if (self = [super init]) {
	}
	return self;
}

- (void)dealloc
{
	[sheet release];
	[super dealloc];
}

- (void)startSheet
{
	[NSApp beginSheet:sheet modalForWindow:window modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void)endSheet
{
	[NSApp endSheet:sheet];
}

- (void)sheetDidEnd:(NSWindow*)sender returnCode:(NSInteger)returnCode contextInfo:(void*)contextInfo
{
	[sheet close];
}

- (void)ok:(id)sender
{
	[self endSheet];
}

- (void)cancel:(id)sender
{
	[self endSheet];
}

@end
