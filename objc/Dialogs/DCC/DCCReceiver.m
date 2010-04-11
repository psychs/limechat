// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "DCCReceiver.h"


@interface DCCReceiver (Private)
- (void)openFile;
- (void)closeFile;
@end


@implementation DCCReceiver

@synthesize delegate;
@synthesize uid;
@synthesize peerNick;
@synthesize host;
@synthesize port;
@synthesize size;
@synthesize processedSize;
@synthesize status;
@synthesize error;
@synthesize path;
@synthesize fileName;
@synthesize downloadFileName;
@synthesize icon;
@synthesize progressBar;

- (id)init
{
	if (self = [super init]) {
	}
	return self;
}

- (void)dealloc
{
	[peerNick release];
	[host release];
	[error release];
	[path release];
	[fileName release];
	[downloadFileName release];
	[icon release];
	[progressBar release];
	
	[sock close];
	[sock autorelease];
	[super dealloc];
}

- (void)setPath:(NSString *)value
{
	if (path != value) {
		[path release];
		path = [[value stringByExpandingTildeInPath] retain];
	}
}

- (void)setFileName:(NSString *)value
{
	if (fileName != value) {
		[fileName release];
		fileName = [value retain];
		
		[icon release];
		icon = [[[NSWorkspace sharedWorkspace] iconForFileType:[fileName pathExtension]] retain];
	}
}

- (double)speed
{
	return 1;
}

- (void)open
{
	if (sock) {
		[self close];
	}

	sock = [TCPClient new];
	sock.delegate = self;
	sock.host = host;
	sock.port = port;
	[sock open];
}

- (void)close
{
	[sock close];
	[sock autorelease];
	sock = nil;
	
	[self closeFile];
	
	if (status != DCC_ERROR && status != DCC_COMPLETE) {
		status = DCC_STOP;
	}
	
	[delegate dccReceiveOnClose:self];
}

- (void)openFile
{
}

- (void)closeFile
{
}

#pragma mark -
#pragma mark TCPClient Delegate

- (void)tcpClientDidConnect:(TCPClient*)sender
{
	LOG_METHOD
	
	processedSize = 0;
	status = DCC_RECEIVING;
	
	[self openFile];
	
	[delegate dccReceiveOnOpen:self];
}

- (void)tcpClientDidDisconnect:(TCPClient*)sender
{
	LOG_METHOD
	
	if (status == DCC_COMPLETE || status == DCC_ERROR) return;
	
	status = DCC_ERROR;
	self.error = @"Disconnected";
	[self close];
	
	[delegate dccReceiveOnError:self];
}

- (void)tcpClient:(TCPClient*)sender error:(NSString*)err
{
	LOG_METHOD
	
	if (status == DCC_COMPLETE || status == DCC_ERROR) return;
	
	status = DCC_ERROR;
	self.error = err;
	[self close];
	
	[delegate dccReceiveOnError:self];
}

- (void)tcpClientDidReceiveData:(TCPClient*)sender
{
	LOG_METHOD
	
	NSData* s = [sock read];
	processedSize += s.length;

	if (s.length) {
		;
	}
}

- (void)tcpClientDidSendData:(TCPClient*)sender
{
}

@end
