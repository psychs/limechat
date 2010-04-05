// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "IRCClient.h"
#import "IRC.h"
#import "IRCWorld.h"
#import "IRCMessage.h"
#import "NSStringHelper.h"
#import "NSDataHelper.h"


@interface IRCClient (Private)
- (void)changeStateOff;
- (BOOL)printBoth:(id)chan type:(LogLineType)type text:(NSString*)text;
- (BOOL)printBoth:(id)chan type:(LogLineType)type nick:(NSString*)nick text:(NSString*)text identified:(BOOL)identified;
- (void)printConsole:(id)chan type:(LogLineType)type text:(NSString*)text;
- (void)printConsole:(id)chan type:(LogLineType)type nick:(NSString*)nick text:(NSString*)text identified:(BOOL)identified;
- (BOOL)printChannel:(IRCChannel*)channel type:(LogLineType)type text:(NSString*)text;
- (BOOL)printChannel:(IRCChannel*)channel type:(LogLineType)type nick:(NSString*)nick text:(NSString*)text identified:(BOOL)identified;
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
#pragma mark Properties

- (NSString*)name
{
	return config.name;
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

- (NSString*)now
{
	return @"00:00 ";
}

- (BOOL)needPrintConsole:(id)chan
{
	IRCChannel* channel = nil;
	if (![chan isKindOfClass:[NSString class]]) {
		channel = chan;
	}
	
	if (!channel.isClient && !channel.config.logToConsole) {
		return NO;
	}
	return channel != world.selectedItem || !channel.log.viewingBottom;
}

- (BOOL)printBoth:(id)chan type:(LogLineType)type text:(NSString*)text
{
	return [self printBoth:chan type:type nick:nil text:text identified:NO];
}

- (BOOL)printBoth:(id)chan type:(LogLineType)type nick:(NSString*)nick text:(NSString*)text identified:(BOOL)identified
{
	BOOL result = [self printChannel:chan type:type nick:nick text:text identified:identified];
	if ([self needPrintConsole:chan]) {
		[self printConsole:chan type:type nick:nick text:text identified:identified];
	}
	return result;
}

- (void)printConsole:(id)chan type:(LogLineType)type text:(NSString*)text
{
	[self printConsole:chan type:type nick:nil text:text identified:NO];
}

- (void)printConsole:(id)chan type:(LogLineType)type nick:(NSString*)nick text:(NSString*)text identified:(BOOL)identified
{
	NSString* time = [self now];
	IRCChannel* channel = nil;
	NSString* channelName = nil;
	NSString* place = nil;
	NSString* nickStr = nil;
	LogLineType memberType = LOG_MEMBER_TYPE_NORMAL;
	int colorNumber = 0;
	id clickContext = nil;
	
	if (chan && [chan isKindOfClass:[NSString class]]) {
		channel = (IRCChannel*)self;
		channelName = chan;
	}
	else if (!chan || channel.isClient) {
		channel = chan;
		channelName = nil;
	}
	else {
		channel = chan;
		channelName = channel.name;
	}
	
	if (channelName && [channelName isChannelName]) {
		place = [NSString stringWithFormat:@"<%@> ", channelName];
	}
	else {
		place = [NSString stringWithFormat:@"<%@> ", config.name];
	}
	
	if (nick.length > 0) {
		if (type == LOG_LINE_TYPE_ACTION) {
			nickStr = [NSString stringWithFormat:@"%@ "];
		}
		else {
			nickStr = [NSString stringWithFormat:@"%@: ", nick];
		}
	}
	
	if (nick && [nick isEqualToString:myNick]) {
		memberType = LOG_MEMBER_TYPE_MYSELF;
	}
	
	if (nick && channel && !channel.isClient) {
		//@@@ nick number
	}
	
	if (channel) {
		if (channel.isClient) {
			clickContext = [NSString stringWithFormat:@"client %d", uid];
		}
		else {
			clickContext = [NSString stringWithFormat:@"channel %d %d", uid, channel.uid];
		}
	}
	
	LogLine* c = [[LogLine new] autorelease];
	c.time = time;
	c.place = place;
	c.nick = nickStr;
	c.body = text;
	c.lineType = type;
	c.memberType = memberType;
	c.nickInfo = nick;
	c.clickInfo = nil;
	c.identified = identified;
	c.nickColorNumber = colorNumber;
	
	[world.consoleLog print:c useKeyword:YES];
}

- (BOOL)printChannel:(id)chan type:(LogLineType)type text:(NSString*)text
{
	return [self printChannel:chan type:type nick:nil text:text identified:NO];
}

- (BOOL)printChannel:(id)chan type:(LogLineType)type nick:(NSString*)nick text:(NSString*)text identified:(BOOL)identified
{
	NSString* time = [self now];
	NSString* channelName = nil;
	IRCChannel* channel = nil;
	NSString* place = nil;
	NSString* nickStr = nil;
	LogLineType memberType = LOG_MEMBER_TYPE_NORMAL;
	int colorNumber = 0;
	
	if (chan && [chan isKindOfClass:[NSString class]]) {
		channelName = chan;
		place = [NSString stringWithFormat:@"<%@> ", channelName];
	}
	else {
		channel = chan;
		channelName = nil;
	}
	
	if (nick.length > 0) {
		if (type == LOG_LINE_TYPE_ACTION) {
			nickStr = [NSString stringWithFormat:@"%@ "];
		}
		else {
			nickStr = [NSString stringWithFormat:@"%@: ", nick];
		}
	}
	
	if (nick && [nick isEqualToString:myNick]) {
		memberType = LOG_MEMBER_TYPE_MYSELF;
	}
	
	if (nick && channel && !channel.isClient) {
		//@@@ nick number
	}
	
	LogLine* c = [[LogLine new] autorelease];
	c.time = time;
	c.place = place;
	c.nick = nickStr;
	c.body = text;
	c.lineType = type;
	c.memberType = memberType;
	c.nickInfo = nick;
	c.clickInfo = nil;
	c.identified = identified;
	c.nickColorNumber = colorNumber;
	
	BOOL keyword = NO;
	
	if (channel && !channel.isClient) {
		keyword = [channel print:c];
	}
	else {
		keyword = [log print:c useKeyword:YES];
	}
	
	return keyword;
}

- (void)printSystem:(id)channel text:(NSString*)text
{
	[self printChannel:channel type:LOG_LINE_TYPE_SYSTEM text:text];
}

- (void)printSystemBoth:(id)channel text:(NSString*)text
{
	[self printBoth:channel type:LOG_LINE_TYPE_SYSTEM text:text];
}

- (void)printReply:(IRCMessage*)m
{
	NSString* text = [m sequence:1];
	[self printBoth:self type:LOG_LINE_TYPE_REPLY text:text];
}

- (void)printUnknownReply:(IRCMessage*)m
{
	NSString* text = [NSString stringWithFormat:@"Reply(%d): %@", m.numericReply, [m sequence:1]];
	[self printBoth:self type:LOG_LINE_TYPE_REPLY text:text];
}

- (void)printErrorReply:(IRCMessage*)m
{
	NSString* text = [NSString stringWithFormat:@"Error(%d): %@", m.numericReply, [m sequence:1]];
	[self printBoth:self type:LOG_LINE_TYPE_ERROR_REPLY text:text];
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
#pragma mark Protocol Handler

- (void)receiveInit:(IRCMessage*)m
{
}

- (void)receiveErrorNumericReply:(IRCMessage*)m
{
}

- (void)receiveNumericReply:(IRCMessage*)m
{
	int n = m.numericReply;
	if (400 <= n && n < 600 && n != 403 && n != 422) {
		[self receiveErrorNumericReply:m];
		return;
	}
	
	[self printReply:m];
}

#pragma mark -
#pragma mark IRCConnection Delegate

- (void)ircConnectionDidConnect:(IRCConnection*)sender
{
	[self printSystemBoth:self text:@"Connected"];
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
	NSStringEncoding enc = encoding;
	if (encoding == NSUTF8StringEncoding && config.fallbackEncoding != NSUTF8StringEncoding && ![data isValidUTF8]) {
		enc = config.fallbackEncoding;
	}
	
	NSString* s = [[NSString alloc] initWithData:data encoding:enc];
	if (!s) {
		s = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
		if (!s) return;
	}
	
	IRCMessage* m = [[[IRCMessage alloc] initWithLine:s] autorelease];
	
	if (m.numericReply > 0) {
		[self receiveNumericReply:m];
	}
	else {
	}
}

- (void)ircConnectionWillSend:(NSString*)line
{
}

@end
