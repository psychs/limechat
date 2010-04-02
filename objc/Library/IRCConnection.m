#import "IRCConnection.h"


@interface IRCConnection (Private)
- (void)tryToSend;
@end


@implementation IRCConnection

@synthesize delegate;

@synthesize host;
@synthesize port;
@synthesize useSSL;

@synthesize useSystemSocks;
@synthesize useSocks;
@synthesize socksVersion;
@synthesize proxyHost;
@synthesize proxyPort;
@synthesize proxyUser;
@synthesize proxyPassword;

- (id)init
{
	if (self = [super init]) {
		sendQueue = [NSMutableArray new];
		timer = [Timer new];
		timer.delegate = self;
	}
	return self;
}

- (void)dealloc
{
	[host release];
	[proxyHost release];
	[proxyUser release];
	[proxyPassword release];
	
	[conn close];
	[conn autorelease];
	
	[sendQueue release];
	[timer stop];
	[timer release];
	
	[super dealloc];
}

- (void)open
{
	[self close];
	
	conn = [TCPClient new];
	conn.delegate = self;
	conn.useSSL = useSSL;
	conn.useSystemSocks = useSystemSocks;
	conn.useSocks = useSocks;
	conn.socksVersion = socksVersion;
	conn.proxyHost = proxyHost;
	conn.proxyPort = proxyPort;
	conn.proxyUser = proxyUser;
	[conn open];
}

- (void)close
{
	[timer stop];
	[sendQueue removeAllObjects];
	[conn close];
	[conn autorelease];
	conn = nil;
}

- (BOOL)active
{
	return [conn active];
}

- (BOOL)connecting
{
	return [conn connecting];
}

- (BOOL)connected
{
	return [conn connected];
}

- (BOOL)readyToSend
{
	return !sending && penalty == 0;
}

- (void)send:(id)m
{
	[sendQueue addObject:m];
	[self tryToSend];
}

- (void)tryToSend
{
	const int PENALTY_THREASHOLD = 3;
	
	if ([sendQueue count] == 0) return;
	if (sending) return;
	if (penalty > PENALTY_THREASHOLD) return;
	
	sending = YES;
	id m = [sendQueue objectAtIndex:0];
	[m build];
	penalty += [m penalty];
	[conn write:[m data]];
	
	if ([delegate respondsToSelector:@selector(ircConnectionWillSend:)]) {
		[delegate ircConnectionWillSend:m];
	}
}

- (void)timerOnTimer:(id)sender
{
	if (penalty > 0) penalty -= 2;
	if (penalty < 0) penalty - 0;
	[self tryToSend];
}

- (void)tcpClientDidConnect:(TCPClient*)sender
{
	[timer start:2];
	[sendQueue removeAllObjects];
	
	if ([delegate respondsToSelector:@selector(ircConnectionDidConnect:)]) {
		[delegate ircConnectionDidConnect:self];
	}
}

- (void)tcpClient:(TCPClient*)sender error:(NSString*)error
{
	[timer stop];
	[sendQueue removeAllObjects];
	
	if ([delegate respondsToSelector:@selector(ircConnectionDidError:)]) {
		[delegate ircConnectionDidError:self];
	}
}

- (void)tcpClientDidDisconnect:(TCPClient*)sender
{
	[timer stop];
	[sendQueue removeAllObjects];
	
	if ([delegate respondsToSelector:@selector(ircConnectionDidDisconnect:)]) {
		[delegate ircConnectionDidDisconnect:self];
	}
}

- (void)tcpClientDidReceiveData:(TCPClient*)sender
{
	while (1) {
		NSData* data = [conn readLine];
		if (!data) break;
		
		if ([delegate respondsToSelector:@selector(ircConnectionDidReceive:)]) {
			[delegate ircConnectionDidReceive:data];
		}
	}
}

- (void)tcpClientDidSendData:(TCPClient*)sender
{
	sending = NO;
	[self tryToSend];
}

@end
