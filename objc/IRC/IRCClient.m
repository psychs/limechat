// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "IRCClient.h"
#import "IRC.h"
#import "IRCWorld.h"
#import "NSStringHelper.h"


@interface IRCClient (Private)
- (void)changeStateOff;
@end


@implementation IRCClient

@synthesize world;
@synthesize log;

@synthesize config;
@synthesize channels;
@synthesize uid;

- (id)init
{
	if (self = [super init]) {
		tryingNick = -1;
		channels = [NSMutableArray new];
	}
	return self;
}

- (void)dealloc
{
	[log release];
	[config release];
	[channels release];
	[conn close];
	[conn autorelease];
	[inputNick release];
	[sentNick release];
	[myNick release];
	[joinMyAddress release];
	[super dealloc];
}

#pragma mark -
#pragma mark Init

- (void)setup:(IRCClientConfig*)seed
{
	config = [seed mutableCopy];
}

#pragma mark -
#pragma mark Utilities

- (void)autoConnect:(int)delay
{
	connectDelay = delay;
	[self connect];
}

- (void)onTimer
{
}

- (void)connect
{
	if (conn) {
		[conn close];
		[conn autorelease];
		conn = nil;
	}
	
	connecting = YES;
	reconnectEnabled = YES;
	reconnectTime = 30;
	retryEnabled = YES;
	retryTime = 30;
	
	NSString* host = config.host;
	if (host) {
		int n = [host findCharacter:' '];
		if (n >= 0) {
			host = [host substringToIndex:n];
		}
	}
	
	conn = [IRCConnection new];
	conn.delegate = self;
	conn.host = host;
	conn.port = config.port;
	conn.useSSL = config.useSSL;
	conn.encoding = config.encoding;
	
	switch (config.proxyType) {
		case PROXY_SOCKS_SYSTEM:
			conn.useSystemSocks = YES;
		case PROXY_SOCKS4:
		case PROXY_SOCKS5:
			conn.useSocks = YES;
			conn.socksVersion = config.proxyType;
			conn.proxyHost = config.proxyHost;
			conn.proxyPort = config.proxyPort;
			conn.proxyUser = config.proxyUser;
			conn.proxyPassword = config.proxyPassword;
			break;
	}
	
	[conn open];
}

- (void)disconnect
{
	if (conn) {
		[conn close];
		[conn autorelease];
		conn = nil;
	}
	
	[self changeStateOff];
}

- (void)sendLine:(NSString*)str
{
	[conn sendLine:str];
	
	LOG(@">>> %@", str);
}

- (void)send:(NSString*)str, ...
{
	NSMutableArray* ary = [NSMutableArray array];
	
	id obj;
	va_list args;
	va_start(args, str);
	while (obj = va_arg(args, id)) {
		[ary addObject:obj];
	}
	va_end(args);
	
	NSMutableString* s = [NSMutableString stringWithString:str];
	
	int count = ary.count;
	for (int i=0; i<count; i++) {
		NSString* e = [ary objectAtIndex:i];
		[s appendString:@" "];
		if (i == count-1 && (e.length == 0 || [e hasPrefix:@":"] || [e contains:@" "])) {
			[s appendString:@":"];
		}
		[s appendString:e];
	}
	
	[self sendLine:s];
}

- (IRCChannel*)findChannel:(NSString*)name
{
	return nil;
}

- (int)indexOfTalkChannel
{
	int i = 0;
	for (IRCChannel* e in channels) {
		if (e.isTalk) return i;
		++i;
	}
	return -1;
}

- (void)updateClientTitle
{
}

- (void)reloadTree
{
}

- (void)changeStateOff
{
	BOOL prevConnected = connected;
	
	[conn autorelease];
	conn = nil;
	
	connecting = connected = login = quitting = NO;
	[myNick release];
	myNick = @"";
	[sentNick release];
	sentNick = @"";
	
	tryingNick = -1;
	[joinMyAddress release];
	joinMyAddress = nil;
	
	inWhois = NO;
	identifyMsg = NO;
	identifyCTCP = NO;
	
	for (IRCChannel* c in channels) {
		if (c.isActive) {
			[c deactivate];
			// print_system
		}
	}
	
	[self updateClientTitle];
	[self reloadTree];
	// print_ssytem_both
	
	if (prevConnected) {
		// notifyEvent
		//[SoundPlayer play:<#(NSString *)name#>]
	}
}

#pragma mark -
#pragma mark Print

- (void)printBoth:(IRCChannel*)channel
{
}

#pragma mark -
#pragma mark IRCTreeItem

- (BOOL)isClient
{
	return YES;
}

- (void)resetState
{
}

- (int)numberOfChildren
{
	return channels.count;
}

- (id)childAtIndex:(int)index
{
	return [channels objectAtIndex:index];
}

- (NSString*)label
{
	return config.name;
}

#pragma mark -
#pragma mark IRCConnection Delegate

- (void)ircConnectionDidConnect:(IRCConnection*)sender
{
	LOG_METHOD
	connecting = login = NO;
	connected = reconnectEnabled = YES;
	encoding = config.encoding;
	
	[inputNick autorelease];
	[sentNick autorelease];
	[myNick autorelease];
	inputNick = [config.nick retain];
	sentNick = [config.nick retain];
	myNick = [config.nick retain];
	
	int myMode = config.invisibleMode ? 8 : 0;
	NSString* realName = config.realName ?: config.nick;
	
	if (config.password.length) [self send:PASS, config.password, nil];
	[self send:NICK, sentNick, nil];
	[self send:USER, config.username, [NSString stringWithFormat:@"%d", myMode], @"*", realName, nil];
	
	[self updateClientTitle];
}

- (void)ircConnectionDidDisconnect:(IRCConnection*)sender
{
	LOG_METHOD
	[self changeStateOff];
}

- (void)ircConnectionDidError:(NSString*)error
{
	LOG(@"Error: %@", error);
}

- (void)ircConnectionDidReceive:(NSData*)data
{
	NSString* s = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	LOG(@"### %@", s);
}

- (void)ircConnectionWillSend:(NSString*)line
{
}

@end
