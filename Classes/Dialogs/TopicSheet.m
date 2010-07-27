// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "TopicSheet.h"


@interface TopicSheet (Private)
@end


@implementation TopicSheet

@synthesize uid;
@synthesize cid;

- (id)init
{
	if (self = [super init]) {
		[NSBundle loadNibNamed:@"TopicSheet" owner:self];
	}
	return self;
}

- (void)dealloc
{
	[super dealloc];
}

- (void)start:(NSString*)topic
{
	[text setStringValue:topic ?: @""];
	[self startSheet];
}

- (void)ok:(id)sender
{
	if ([delegate respondsToSelector:@selector(topicSheet:onOK:)]) {
		[delegate topicSheet:self onOK:[text stringValue]];
	}
	
	[super ok:nil];
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification*)note
{
	if ([delegate respondsToSelector:@selector(topicSheetWillClose:)]) {
		[delegate topicSheetWillClose:self];
	}
}

@end
