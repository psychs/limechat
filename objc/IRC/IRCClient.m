// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "IRCClient.h"
#import "IRC.h"
#import "IRCWorld.h"
#import "IRCMessage.h"
#import "NSStringHelper.h"
#import "NSDataHelper.h"


#define MAX_JOIN_CHANNELS	10
#define MAX_BODY_LEN		480


@interface IRCClient (Private)
- (void)sendLine:(NSString*)str;
- (void)send:(NSString*)str, ...;

- (void)setKeywordState:(id)target;
- (void)setNewTalkState:(id)target;
- (void)setUnreadState:(id)target;

- (void)receivePrivmsgAndNotice:(IRCMessage*)message;
- (void)receiveJoin:(IRCMessage*)message;
- (void)receivePart:(IRCMessage*)message;
- (void)receiveKick:(IRCMessage*)message;
- (void)receiveQuit:(IRCMessage*)message;
- (void)receiveKill:(IRCMessage*)message;
- (void)receiveNick:(IRCMessage*)message;
- (void)receiveMode:(IRCMessage*)message;
- (void)receiveTopic:(IRCMessage*)message;
- (void)receiveInvite:(IRCMessage*)message;
- (void)receiveError:(IRCMessage*)message;
- (void)receivePing:(IRCMessage*)message;
- (void)receiveNumericReply:(IRCMessage*)message;

- (void)receiveInit:(IRCMessage*)message;
- (void)receiveText:(IRCMessage*)m command:(NSString*)cmd text:(NSString*)text identified:(BOOL)identified;
- (void)receiveErrorNumericReply:(IRCMessage*)message;
- (void)receiveNickCollision:(IRCMessage*)message;
- (void)receiveCTCPQuery:(IRCMessage*)message text:(NSString*)text;
- (void)receiveCTCPReply:(IRCMessage*)message text:(NSString*)text;

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
@synthesize loggedIn;

@synthesize isKeyword;
@synthesize isUnread;

@synthesize lastSelectedChannel;

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
	[serverHostname release];
	[joinMyAddress release];
	[lastSelectedChannel release];
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

- (BOOL)isNewTalk
{
	return NO;
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

- (BOOL)sendText:(NSString*)s command:(NSString*)command
{
	if (!connected) return NO;
	
	id sel = world.selected;
	if (!sel) return NO;
	if ([sel isClient]) {
		[self sendLine:s];
	}
	else {
		[self send:command, [sel name], s, nil];
		[self printBoth:sel type:LINE_TYPE_PRIVMSG nick:myNick text:s identified:YES];
	}
	
	return YES;
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
	for (IRCChannel* c in channels) {
		if ([c.name isEqualNoCase:name]) {
			return c;
		}
	}
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
	[world reloadTree];
}

- (void)changeStateOff
{
	BOOL prevConnected = connected;
	
	[conn autorelease];
	conn = nil;
	
	connecting = connected = loggedIn = quitting = NO;
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

- (void)quickJoin:(NSArray*)chans
{
	NSMutableString* target = [NSMutableString string];
	NSMutableString* pass = [NSMutableString string];
	
	for (IRCChannel* c in chans) {
		NSMutableString* prevTarget = [[target mutableCopy] autorelease];
		NSMutableString* prevPass = [[pass mutableCopy] autorelease];
		
		if (!target.isEmpty) [target appendString:@","];
		[target appendString:c.name];
		if (!c.password.isEmpty) {
			if (!pass.isEmpty) [pass appendString:@","];
			[pass appendString:c.password];
		}
		
		NSData* targetData = [target dataUsingEncoding:conn.encoding];
		NSData* passData = [pass dataUsingEncoding:conn.encoding];
		
		if (targetData.length + passData.length > MAX_BODY_LEN) {
			if (!prevTarget.isEmpty) {
				if (prevPass.isEmpty) {
					[self send:JOIN, prevTarget, nil];
				}
				else {
					[self send:JOIN, prevTarget, prevPass, nil];
				}
				[target setString:c.name];
				[pass setString:c.password];
			}
			else {
				if (c.password.isEmpty) {
					[self send:JOIN, c.name, nil];
				}
				else {
					[self send:JOIN, c.name, c.password, nil];
				}
				[target setString:@""];
				[pass setString:@""];
			}
		}
	}
	
	if (!target.isEmpty) {
		if (pass.isEmpty) {
			[self send:JOIN, target, nil];
		}
		else {
			[self send:JOIN, target, pass, nil];
		}
	}
}

- (void)joinChannels:(NSArray*)chans
{
	NSMutableArray* ary = [NSMutableArray array];
	BOOL pass = YES;
	
	for (IRCChannel* c in chans) {
		BOOL hasPass = !c.password.isEmpty;
		
		if (pass) {
			pass = hasPass;
			[ary addObject:c];
		}
		else {
			if (hasPass) {
				[self quickJoin:ary];
				[ary removeAllObjects];
				pass = hasPass;
			}
			[ary addObject:c];
		}
		
		if (ary.count >= MAX_JOIN_CHANNELS) {
			[self quickJoin:ary];
			[ary removeAllObjects];
			pass = YES;
		}
	}
	
	if (ary.count > 0) {
		[self quickJoin:ary];
	}
}

- (void)setKeywordState:(id)t
{
	if ([NSApp isActive] && world.selected == t) return;
	if ([t isKeyword]) return;
	[t setIsKeyword:YES];
	[self reloadTree];
	if (![NSApp isActive]) [NSApp requestUserAttention:NSInformationalRequest];
	[world updateIcon];
}

- (void)setNewTalkState:(id)t
{
	if ([NSApp isActive] && world.selected == t) return;
	if ([t isNewTalk]) return;
	[t setIsNewTalk:YES];
	[self reloadTree];
	if (![NSApp isActive]) [NSApp requestUserAttention:NSInformationalRequest];
	[world updateIcon];
}

- (void)setUnreadState:(id)t
{
	if ([NSApp isActive] && world.selected == t) return;
	if ([t isUnread]) return;
	[t setIsUnread:YES];
	[self reloadTree];
	[world updateIcon];
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
	return channel != world.selected || !channel.log.viewingBottom;
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
	LogLineType memberType = MEMBER_TYPE_NORMAL;
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
		if (type == LINE_TYPE_ACTION) {
			nickStr = [NSString stringWithFormat:@"%@ "];
		}
		else {
			nickStr = [NSString stringWithFormat:@"%@: ", nick];
		}
	}
	
	if (nick && [nick isEqualToString:myNick]) {
		memberType = MEMBER_TYPE_MYSELF;
	}
	
	if (nick && channel && !channel.isClient) {
		//@@@ nick number
	}
	
	if (channel && !channel.isClient) {
		clickContext = [NSString stringWithFormat:@"channel %d %d", uid, channel.uid];
	}
	else {
		clickContext = [NSString stringWithFormat:@"client %d", uid];
	}
	
	LogLine* c = [[LogLine new] autorelease];
	c.time = time;
	c.place = place;
	c.nick = nickStr;
	c.body = text;
	c.lineType = type;
	c.memberType = memberType;
	c.nickInfo = nick;
	c.clickInfo = clickContext;
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
	LogLineType memberType = MEMBER_TYPE_NORMAL;
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
		if (type == LINE_TYPE_ACTION) {
			nickStr = [NSString stringWithFormat:@"%@ "];
		}
		else {
			nickStr = [NSString stringWithFormat:@"%@: ", nick];
		}
	}
	
	if (nick && [nick isEqualToString:myNick]) {
		memberType = MEMBER_TYPE_MYSELF;
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
	[self printChannel:channel type:LINE_TYPE_SYSTEM text:text];
}

- (void)printSystemBoth:(id)channel text:(NSString*)text
{
	[self printBoth:channel type:LINE_TYPE_SYSTEM text:text];
}

- (void)printReply:(IRCMessage*)m
{
	NSString* text = [m sequence:1];
	[self printBoth:self type:LINE_TYPE_REPLY text:text];
}

- (void)printUnknownReply:(IRCMessage*)m
{
	NSString* text = [NSString stringWithFormat:@"Reply(%d): %@", m.numericReply, [m sequence:1]];
	[self printBoth:self type:LINE_TYPE_REPLY text:text];
}

- (void)printErrorReply:(IRCMessage*)m
{
	NSString* text = [NSString stringWithFormat:@"Error(%d): %@", m.numericReply, [m sequence:1]];
	[self printBoth:self type:LINE_TYPE_ERROR_REPLY text:text];
}

#pragma mark -
#pragma mark IRCTreeItem

- (BOOL)isClient
{
	return YES;
}

- (BOOL)isActive
{
	return loggedIn;
}

- (IRCClient*)client
{
	return self;
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

- (void)receivePrivmsgAndNotice:(IRCMessage*)m
{
	NSString* text = [m paramAt:1];
	
	BOOL identified = NO;
	if (identifyCTCP && ([text hasPrefix:@"+\x01"] || [text hasPrefix:@"-\x01"])) {
		identified = [text hasPrefix:@"+"];
		text = [text substringFromIndex:1];
	}
	else if (identifyMsg && [text hasPrefix:@"+"] || [text hasPrefix:@"-"]) {
		identified = [text hasPrefix:@"+"];
		text = [text substringFromIndex:1];
	}
	
	if ([text hasPrefix:@"\x01"]) {
		//
		// CTCP
		//
		text = [text substringFromIndex:1];
		int n = [text findString:@"\x01"];
		if (n >= 0) {
			text = [text substringToIndex:n];
		}
		
		if ([m.command isEqualToString:PRIVMSG]) {
			if ([[text uppercaseString] hasPrefix:@"ACTION "]) {
				text = [text substringFromIndex:7];
				[self receiveText:m command:ACTION text:text identified:identified];
			}
			else {
				[self receiveCTCPQuery:m text:text];
			}
		}
		else {
			[self receiveCTCPReply:m text:text];
		}
	}
	else {
		[self receiveText:m command:m.command text:text identified:identified];
	}
}

- (void)receiveText:(IRCMessage*)m command:(NSString*)cmd text:(NSString*)text identified:(BOOL)identified
{
	NSString* nick = m.sender.nick;
	NSString* target = [m paramAt:0];
	
	LogLineType type = LINE_TYPE_PRIVMSG;
	if ([cmd isEqualToString:NOTICE]) {
		type = LINE_TYPE_NOTICE;
	}
	else if ([cmd isEqualToString:ACTION]) {
		type = LINE_TYPE_ACTION;
	}
	
	if ([target hasPrefix:@"@"]) {
		target = [target substringFromIndex:1];
	}
	
	if (target.isChannelName) {
		//
		// channel
		//
		
		IRCChannel* c = [self findChannel:target];
		BOOL keyword = [self printBoth:(c ?: (id)target) type:type nick:nick text:text identified:identified];

		id t = c ?: (id)self;
		[self setUnreadState:t];
		if (keyword) [self setKeywordState:t];
	}
	else if ([target isEqualNoCase:myNick]) {
		if (!nick.length || [nick contains:@"."]) {
			// system
			[self printBoth:self type:type text:text];
		}
		else {
			// talk
			IRCChannel* c = [self findChannel:nick];
			BOOL newTalk = NO;
			if (!c && type != LINE_TYPE_NOTICE) {
				c = [world createTalk:nick client:self];
				newTalk = YES;
			}
			
			BOOL keyword = [self printBoth:(c ?: (id)target) type:type nick:nick text:text identified:identified];
			
			if (type == LINE_TYPE_NOTICE) {
				;
			}
			else {
				id t = c ?: (id)self;
				[self setUnreadState:t];
				if (keyword) [self setKeywordState:t];
				if (newTalk) [self setNewTalkState:t];
			}
		}
	}
	else {
		// system
		[self printBoth:self type:type nick:nick text:text identified:identified];
	}
}

- (void)receiveCTCPQuery:(IRCMessage*)m text:(NSString*)text
{
}

- (void)receiveCTCPReply:(IRCMessage*)m text:(NSString*)text
{
}

- (void)receiveJoin:(IRCMessage*)m
{
	NSString* nick = m.sender.nick;
	NSString* chname = [m paramAt:0];
	BOOL myself = [nick isEqualNoCase:myNick];

	BOOL njoin = NO;
	if ([chname hasSuffix:@"\x07o"]) {
		njoin = YES;
		chname = [chname substringToIndex:chname.length - 2];
	}
	
	IRCChannel* c = [self findChannel:chname];
	
	if (myself) {
		if (!c) {
			IRCChannelConfig* seed = [[IRCChannelConfig new] autorelease];
			seed.name = chname;
			[world createChannel:seed client:self reload:YES adjust:YES];
			[world save];
		}
		[c activate];
		[self reloadTree];
		[self printSystem:c text:@"You have joined the channel"];
		
		if (!joinMyAddress) {
			joinMyAddress = [m.sender.address retain];
		}
	}
	
	NSString* text = [NSString stringWithFormat:@"%@ has joined (%@@%@)", nick, m.sender.user, m.sender.address];
	[self printBoth:(c ?: (id)chname) type:LINE_TYPE_JOIN text:text];
}

- (void)receivePart:(IRCMessage*)m
{
}

- (void)receiveKick:(IRCMessage*)m
{
}

- (void)receiveQuit:(IRCMessage*)m
{
}

- (void)receiveKill:(IRCMessage*)m
{
}

- (void)receiveNick:(IRCMessage*)m
{
}

- (void)receiveMode:(IRCMessage*)m
{
}

- (void)receiveTopic:(IRCMessage*)m
{
}

- (void)receiveInvite:(IRCMessage*)m
{
}

- (void)receiveError:(IRCMessage*)m
{
}

- (void)receivePing:(IRCMessage*)m
{
	LOG_METHOD
	[self send:PONG, [m sequence:0], nil];
}

- (void)receiveInit:(IRCMessage*)m
{
	if (loggedIn) return;
	
	[world expandClient:self];
	
	loggedIn = YES;
	tryingNick = -1;
	
	[serverHostname release];
	serverHostname = [m.sender.raw retain];
	[myNick release];
	myNick = [[m paramAt:0] retain];
	inWhois = NO;
	
	[self printSystem:self text:@"Logged in"];
	
	if (config.nickPassword.length > 0) {
		[self send:PRIVMSG, @"NickServ", [NSString stringWithFormat:@"IDENTIFY %@", config.nickPassword], nil];
	}
	
	for (NSString* s in config.loginCommands) {
		//@@@
	}
	
	for (IRCChannel* c in channels) {
		if (c.isChannel) {
			// channel
		}
		else {
			// talk
			[c activate];
			
			// @@@ add members
		}
	}
	
	[self updateClientTitle];
	[self reloadTree];
	
	NSMutableArray* ary = [NSMutableArray array];
	for (IRCChannel* c in channels) {
		if (c.isChannel && c.config.autoJoin) {
			[ary addObject:c];
		}
	}
	
	[self joinChannels:ary];
}

- (void)receiveErrorNumericReply:(IRCMessage*)m
{
	[self printErrorReply:m];
}

- (void)receiveNickCollision:(IRCMessage*)m
{
}

- (void)receiveNumericReply:(IRCMessage*)m
{
	int n = m.numericReply;
	if (400 <= n && n < 600 && n != 403 && n != 422) {
		[self receiveErrorNumericReply:m];
		return;
	}
	
	switch (n) {
		case 1:
		case 376:
		case 422:
			[self receiveInit:m];
			[self printReply:m];
			break;
		default:
			[self printUnknownReply:m];
			break;
	}
}

#pragma mark -
#pragma mark IRCConnection Delegate

- (void)ircConnectionDidConnect:(IRCConnection*)sender
{
	[self printSystemBoth:self text:@"Connected"];
	connecting = loggedIn = NO;
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
	NSString* cmd = m.command;
	
	if (m.numericReply > 0) [self receiveNumericReply:m];
	else if ([cmd isEqualToString:PRIVMSG] || [cmd isEqualToString:NOTICE]) [self receivePrivmsgAndNotice:m];
	else if ([cmd isEqualToString:JOIN]) [self receiveJoin:m];
	else if ([cmd isEqualToString:PART]) [self receivePart:m];
	else if ([cmd isEqualToString:KICK]) [self receiveKick:m];
	else if ([cmd isEqualToString:QUIT]) [self receiveQuit:m];
	else if ([cmd isEqualToString:KILL]) [self receiveKill:m];
	else if ([cmd isEqualToString:NICK]) [self receiveNick:m];
	else if ([cmd isEqualToString:MODE]) [self receiveMode:m];
	else if ([cmd isEqualToString:TOPIC]) [self receiveTopic:m];
	else if ([cmd isEqualToString:INVITE]) [self receiveInvite:m];
	else if ([cmd isEqualToString:ERROR]) [self receiveError:m];
	else if ([cmd isEqualToString:PING]) [self receivePing:m];
}

- (void)ircConnectionWillSend:(NSString*)line
{
}

@end
