// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "HostResolver.h"


@implementation HostResolver

@synthesize delegate;

- (id)initWithDelegate:(id)aDelegate
{
	if (self = [super init]) {
		delegate = aDelegate;
	}
	return self;
}

- (void)resolve:(NSString*)hostname
{
	if (hostname.length) {
		[NSThread detachNewThreadSelector:@selector(resolveInternal:) toTarget:self withObject:hostname];
	}
}

- (void)resolveInternal:(NSString*)hostname
{
	[self retain];
	
	NSAutoreleasePool* pool = [NSAutoreleasePool new];
	
	NSHost* host = [NSHost hostWithName:hostname];
	NSArray* info = [NSArray arrayWithObjects:hostname, host, nil];
	[self performSelectorOnMainThread:@selector(hostResolved:) withObject:info waitUntilDone:YES];
	
	[pool release];
	
	[self release];
}

- (void)hostResolved:(NSArray*)info
{
	if (!delegate) return;
	
	if ([info count] == 2) {
		NSHost* host = [info objectAtIndex:1];
		if ([delegate respondsToSelector:@selector(hostResolver:didResolve:)]) {
			[delegate hostResolver:self didResolve:host];
		}
	}
	else {
		NSString* hostname = [info objectAtIndex:0];
		if ([delegate respondsToSelector:@selector(hostResolver:didNotResolve:)]) {
			[delegate hostResolver:self didNotResolve:hostname];
		}
	}
}

@end
