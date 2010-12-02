// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "IRCClient.h"
#import "IRC.h"
#import "IRCWorld.h"
#import "IRCMessage.h"
#import "Preferences.h"
#import "WhoisDialog.h"
#import "OnigRegexp.h"
#import "SoundPlayer.h"
#import "TimerCommand.h"
#import "NSStringHelper.h"
#import "NSDataHelper.h"
#import "NSData+Kana.h"


#define MAX_JOIN_CHANNELS	10
#define MAX_BODY_LEN		480
#define TIME_BUFFER_SIZE	256

#define PONG_INTERVAL		130
#define QUIT_INTERVAL		5
#define RECONNECT_INTERVAL	20
#define RETRY_INTERVAL		240
#define NICKSERV_INTERVAL	5

#define CTCP_MIN_INTERVAL	5


static NSDateFormatter* dateTimeFormatter = nil;



@interface IRCClient (Private)
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
- (void)receiveCTCPQuery:(IRCMessage*)message text:(NSString*)text;
- (void)receiveCTCPReply:(IRCMessage*)message text:(NSString*)text;
- (void)receiveDCCSend:(IRCMessage*)m fileName:(NSString*)fileName address:(NSString*)address port:(int)port fileSize:(long long)size;
- (void)receiveErrorNumericReply:(IRCMessage*)message;
- (void)receiveNickCollisionError:(IRCMessage*)message;
- (void)tryAnotherNick;

- (void)changeStateOff;
- (BOOL)printBoth:(id)chan type:(LogLineType)type text:(NSString*)text;
- (BOOL)printBoth:(id)chan type:(LogLineType)type nick:(NSString*)nick text:(NSString*)text identified:(BOOL)identified;
- (void)printConsole:(id)chan type:(LogLineType)type text:(NSString*)text;
- (void)printConsole:(id)chan type:(LogLineType)type nick:(NSString*)nick text:(NSString*)text identified:(BOOL)identified;
- (BOOL)printChannel:(IRCChannel*)channel type:(LogLineType)type text:(NSString*)text;
- (BOOL)printChannel:(IRCChannel*)channel type:(LogLineType)type nick:(NSString*)nick text:(NSString*)text identified:(BOOL)identified;
- (void)printSystem:(id)channel text:(NSString*)text;
- (void)printSystemBoth:(id)channel text:(NSString*)text;
- (void)printReply:(IRCMessage*)m;
- (void)printUnknownReply:(IRCMessage*)m;
- (void)printErrorReply:(IRCMessage*)m;
- (void)printErrorReply:(IRCMessage*)m channel:(IRCChannel*)channel;
- (void)printError:(NSString*)error;

- (void)notifyText:(GrowlNotificationType)type target:(id)target nick:(NSString*)nick text:(NSString*)text;
- (void)notifyEvent:(GrowlNotificationType)type;
- (void)notifyEvent:(GrowlNotificationType)type target:(id)target nick:(NSString*)nick text:(NSString*)text;

- (WhoisDialog*)createWhoisDialogWithNick:(NSString*)nick username:(NSString*)username address:(NSString*)address realname:(NSString*)realname;
- (WhoisDialog*)findWhoisDialog:(NSString*)nick;

- (void)performAutoJoin;
- (void)joinChannels:(NSArray*)chans;
- (void)checkRejoin:(IRCChannel*)c;

- (void)addCommandToCommandQueue:(TimerCommand*)m;
- (void)clearCommandQueue;
@end


@implementation IRCClient

@synthesize world;

@synthesize config;
@synthesize channels;
@synthesize isupport;
@synthesize myMode;
@synthesize isConnecting;
@synthesize isConnected;
@synthesize isLoggedIn;

@synthesize myNick;
@synthesize myAddress;

@synthesize lastSelectedChannel;

@synthesize propertyDialog;

- (id)init
{
	if (self = [super init]) {
		tryingNickNumber = -1;
		channels = [NSMutableArray new];
		isupport = [IRCISupportInfo new];
		myMode = [IRCUserMode new];
		whoisDialogs = [NSMutableArray new];
		
		nameResolver = [HostResolver new];
		nameResolver.delegate = self;
		
		pongTimer = [Timer new];
		pongTimer.delegate = self;
		pongTimer.reqeat = YES;
		pongTimer.selector = @selector(onPongTimer:);
		
		quitTimer = [Timer new];
		quitTimer.delegate = self;
		quitTimer.reqeat = NO;
		quitTimer.selector = @selector(onQuitTimer:);
		
		reconnectTimer = [Timer new];
		reconnectTimer.delegate = self;
		reconnectTimer.reqeat = NO;
		reconnectTimer.selector = @selector(onReconnectTimer:);
		
		retryTimer = [Timer new];
		retryTimer.delegate = self;
		retryTimer.reqeat = NO;
		retryTimer.selector = @selector(onRetryTimer:);
		
		autoJoinTimer = [Timer new];
		autoJoinTimer.delegate = self;
		autoJoinTimer.reqeat = NO;
		autoJoinTimer.selector = @selector(onAutoJoinTimer:);
		
		commandQueueTimer = [Timer new];
		commandQueueTimer.delegate = self;
		commandQueueTimer.reqeat = NO;
		commandQueueTimer.selector = @selector(onCommandQueueTimer:);
		
		commandQueue = [NSMutableArray new];

	}
	return self;
}

- (void)dealloc
{
	[config release];
	[channels release];
	[isupport release];
	[myMode release];
	[conn close];
	[conn autorelease];
	
	[inputNick release];
	[sentNick release];
	[myNick release];
	
	[serverHostname release];
	
	nameResolver.delegate = nil;
	[nameResolver autorelease];
	[joinMyAddress release];
	[myAddress release];
	
	[pongTimer stop];
	[pongTimer release];
	[quitTimer stop];
	[quitTimer release];
	[reconnectTimer stop];
	[reconnectTimer release];
	[retryTimer stop];
	[retryTimer release];
	[autoJoinTimer stop];
	[autoJoinTimer release];
	[commandQueueTimer stop];
	[commandQueueTimer release];
	[commandQueue release];
	
	[lastSelectedChannel release];
	[whoisDialogs release];
	[channelListDialog release];
	[propertyDialog release];
	[super dealloc];
}

#pragma mark -
#pragma mark Init

- (void)setup:(IRCClientConfig*)seed
{
	[config autorelease];
	config = [seed mutableCopy];

	addressDetectionMethod = [Preferences dccAddressDetectionMethod];
	if (addressDetectionMethod == ADDRESS_DETECT_SPECIFY) {
		NSString* host = [Preferences dccMyaddress];
		if (host.length) {
			[nameResolver resolve:host];
		}
	}
}

- (void)updateConfig:(IRCClientConfig*)seed
{
	[config autorelease];
	config = [seed mutableCopy];
	
	NSArray* chans = config.channels;
	
	NSMutableArray* ary = [NSMutableArray array];
	
	for (IRCChannelConfig* i in chans) {
		IRCChannel* c = [self findChannel:i.name];
		if (c) {
			[c updateConfig:i];
			[ary addObject:c];
			[channels removeObjectIdenticalTo:c];
		}
		else {
			c = [world createChannel:i client:self reload:NO adjust:NO];
			[ary addObject:c];
		}
	}
	
	for (IRCChannel* c in channels) {
		if (c.isChannel) {
			[self partChannel:c];
		}
		else {
			[ary addObject:c];
		}
	}
	
	[channels removeAllObjects];
	[channels addObjectsFromArray:ary];
	
	[config.channels removeAllObjects];

	[world reloadTree];
	[world adjustSelection];
}

- (IRCClientConfig*)storedConfig
{
	IRCClientConfig* u = [[config mutableCopy] autorelease];
	u.uid = uid;
	[u.channels removeAllObjects];
	
	for (IRCChannel* c in channels) {
		if (c.isChannel) {
			[u.channels addObject:[[c.config mutableCopy] autorelease]];
		}
	}
	
	return u;
}

- (NSMutableDictionary*)dictionaryValue
{
	NSMutableDictionary* dic = [config dictionaryValue];
	
	NSMutableArray* ary = [NSMutableArray array];
	for (IRCChannel* c in channels) {
		if (c.isChannel) {
			[ary addObject:[c dictionaryValue]];
		}
	}
	
	[dic setObject:ary forKey:@"channels"];
	return dic;
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

- (BOOL)isReconnecting
{
	return reconnectTimer && reconnectTimer.isActive;
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

- (void)terminate
{
	[self quit];
	[self closeDialogs];
	for (IRCChannel* c in channels) {
		[c terminate];
	}
	[self disconnect];
}

- (void)closeDialogs
{
	for (WhoisDialog* d in whoisDialogs) {
		[d close];
	}
	[whoisDialogs removeAllObjects];
	
	[channelListDialog close];
	[channelListDialog release];
}

- (void)preferencesChanged
{
	log.maxLines = [Preferences maxLogLines];
	
	if (addressDetectionMethod != [Preferences dccAddressDetectionMethod]) {
		addressDetectionMethod = [Preferences dccAddressDetectionMethod];
		
		[myAddress release];
		myAddress = nil;
		
		if (addressDetectionMethod == ADDRESS_DETECT_SPECIFY) {
			NSString* host = [Preferences dccMyaddress];
			if (host.length) {
				[nameResolver resolve:host];
			}
		}
		else {
			if (joinMyAddress.length) {
				[nameResolver resolve:joinMyAddress];
			}
		}
	}
	
	for (IRCChannel* c in channels) {
		[c preferencesChanged];
	}
}

- (void)reloadTree
{
	[world reloadTree];
}

- (BOOL)checkIgnore:(NSString*)text nick:(NSString*)nick channel:(NSString*)channel
{
	for (IgnoreItem* g in config.ignores) {
		if ([g checkIgnore:text nick:nick channel:channel]) {
			return YES;
		}
	}
		
	return NO;
}

#pragma mark -
#pragma mark ListDialog

- (void)createChannelListDialog
{
	if (!channelListDialog) {
		channelListDialog = [ListDialog new];
		channelListDialog.delegate = self;
		[channelListDialog start];
	}
	else {
		[channelListDialog show];
	}
}

- (void)listDialogOnUpdate:(ListDialog*)sender
{
	[self sendLine:LIST];
}

- (void)listDialogOnJoin:(ListDialog*)sender channel:(NSString*)channel
{
	[self send:JOIN, channel, nil];
}

- (void)listDialogWillClose:(ListDialog*)sender
{
	[channelListDialog autorelease];
	channelListDialog = nil;
}

#pragma mark -
#pragma mark Timers

- (void)startPongTimer
{
	if (pongTimer.isActive) return;
	
	[pongTimer start:PONG_INTERVAL];
}

- (void)stopPongTimer
{
	[pongTimer stop];
}

- (void)onPongTimer:(id)sender
{
	if (isLoggedIn) {
		if (serverHostname.length) {
			[self send:PONG, serverHostname, nil];
		}
	}
	else {
		[self stopPongTimer];
	}
}

- (void)startQuitTimer
{
	if (quitTimer.isActive) return;
	
	[quitTimer start:QUIT_INTERVAL];
}

- (void)stopQuitTimer
{
	[quitTimer stop];
}

- (void)onQuitTimer:(id)sender
{
	[self disconnect];
}

- (void)startReconnectTimer
{
	if (reconnectTimer.isActive) return;
	
	[reconnectTimer start:RECONNECT_INTERVAL];
}

- (void)stopReconnectTimer
{
	[reconnectTimer stop];
}

- (void)onReconnectTimer:(id)sender
{
	[self connect:CONNECT_RECONNECT];
}

- (void)startRetryTimer
{
	if (retryTimer.isActive) return;
	
	[retryTimer start:RETRY_INTERVAL];
}

- (void)stopRetryTimer
{
	[retryTimer stop];
}

- (void)onRetryTimer:(id)sender
{
	[self disconnect];
	[self connect:CONNECT_RETRY];
}

- (void)startAutoJoinTimer
{
	[autoJoinTimer stop];
	[autoJoinTimer start:NICKSERV_INTERVAL];
}

- (void)stopAutoJoinTimer
{
	[autoJoinTimer stop];
}

- (void)onAutoJoinTimer:(id)sender
{
	[self performAutoJoin];
}

#pragma mark -
#pragma mark Commands

- (void)connect
{
	[self connect:CONNECT_NORMAL];
}

- (void)connect:(ConnectMode)mode
{
	[self stopReconnectTimer];
	
	if (conn) {
		[conn close];
		[conn autorelease];
		conn = nil;
	}
	
	switch (mode) {
		case CONNECT_NORMAL:
			[self printSystemBoth:nil text:@"Connecting…"];
			break;
		case CONNECT_RECONNECT:
			[self printSystemBoth:nil text:@"Reconnecting…"];
			break;
		case CONNECT_RETRY:
			[self printSystemBoth:nil text:@"Retrying…"];
			break;
	}
	
	isConnecting = YES;
	reconnectEnabled = YES;
	retryEnabled = YES;
	
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
			// fall through
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

- (void)quit
{
	[self quit:nil];
}

- (void)quit:(NSString*)comment
{
	if (!isLoggedIn) {
		[self disconnect];
		return;
	}
	
	isQuitting = YES;
	reconnectEnabled = NO;
	[conn clearSendQueue];
	[self send:QUIT, comment ?: config.leavingComment, nil];
	
	[self startQuitTimer];
}

- (void)cancelReconnect
{
	[self stopReconnectTimer];
}

- (void)changeNick:(NSString*)newNick
{
	if (!isConnected) return;
	
	[inputNick autorelease];
	[sentNick autorelease];
	inputNick = [newNick retain];
	sentNick = [newNick retain];
	
	[self send:NICK, newNick, nil];
}

- (void)joinChannel:(IRCChannel*)channel
{
	if (!isLoggedIn) return;
	if (channel.isActive) return;
	
	NSString* password = channel.config.password;
	if (!password.length) password = nil;
	
	[self send:JOIN, channel.name, password, nil];
}

- (void)joinChannel:(IRCChannel*)channel password:(NSString*)password
{
	if (!isLoggedIn) return;
	
	if (!password.length) password = channel.config.password;
	if (!password.length) password = nil;
	
	[self send:JOIN, channel.name, password, nil];
}

- (void)partChannel:(IRCChannel*)channel
{
	if (!isLoggedIn) return;
	if (!channel.isActive) return;
	
	NSString* comment = config.leavingComment;
	if (!comment.length) comment = nil;
	
	[self send:PART, channel.name, comment, nil];
}

- (void)sendWhois:(NSString*)nick
{
	if (!isLoggedIn) return;
	
	[self send:WHOIS, nick, nick, nil];
}

- (void)changeOp:(IRCChannel*)channel users:(NSArray*)inputUsers mode:(char)mode value:(BOOL)value
{
	if (!isLoggedIn || !channel || !channel.isActive || !channel.isChannel || !channel.isOp) return;
	
	NSMutableArray* users = [NSMutableArray array];
	
	for (IRCUser* user in inputUsers) {
		IRCUser* m = [channel findMember:user.nick];
		if (m) {
			if (value != [m hasMode:mode]) {
				[users addObject:m];
			}
		}
	}
	
	int max = isupport.modesCount;
	while (users.count) {
		NSArray* ary = [users subarrayWithRange:NSMakeRange(0, MIN(max, users.count))];
		
		NSMutableString* s = [NSMutableString string];
		[s appendFormat:@"%@ %@ %c", MODE, channel.name, value ? '+' : '-'];
		
		for (int i=ary.count-1; i>=0; --i) {
			[s appendFormat:@"%c", mode];
		}
		
		for (IRCUser* m in ary) {
			[s appendString:@" "];
			[s appendString:m.nick];
		}
		
		[self sendLine:s];
		
		[users removeObjectsInRange:NSMakeRange(0, ary.count)];
	}
}

- (void)kick:(IRCChannel*)channel target:(NSString*)nick
{
	[self send:KICK, channel.name, nick, nil];
}

- (void)sendFile:(NSString*)nick port:(int)port fileName:(NSString*)fileName size:(long long)size
{
	NSString* escapedFileName = [fileName stringByReplacingOccurrencesOfString:@" " withString:@"_"];
	
	static OnigRegexp* addressPattern = nil;
	if (!addressPattern) {
		NSString* pattern = @"([0-9]{1,3})\\.([0-9]{1,3})\\.([0-9]{1,3})\\.([0-9]{1,3})";
		addressPattern = [[OnigRegexp compile:pattern] retain];
	}
	
	OnigResult* result = [addressPattern match:myAddress];
	
	NSString* address;
	if (!result) {
		address = myAddress;
	}
	else {
		int w = [[myAddress substringWithRange:[result rangeAt:1]] intValue];
		int x = [[myAddress substringWithRange:[result rangeAt:2]] intValue];
		int y = [[myAddress substringWithRange:[result rangeAt:3]] intValue];
		int z = [[myAddress substringWithRange:[result rangeAt:4]] intValue];
		
		unsigned long long a = 0;
		a |= w; a <<= 8;
		a |= x; a <<= 8;
		a |= y; a <<= 8;
		a |= z;
		
		address = [NSString stringWithFormat:@"%qu", a];
	}
	
	NSString* trail = [NSString stringWithFormat:@"%@ %@ %d %qi", escapedFileName, address, port, size];
	[self sendCTCPQuery:nick command:@"DCC SEND" text:trail];
	
	NSString* text = [NSString stringWithFormat:@"Trying file transfer to %@, %@ (%qi bytes) %@:%d", nick, fileName, size, myAddress, port];
	[self printBoth:nil type:LINE_TYPE_DCC_SEND_SEND text:text];
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

- (void)performAutoJoin
{
	registeringToNickServ = NO;
	[self stopAutoJoinTimer];

	NSMutableArray* ary = [NSMutableArray array];
	for (IRCChannel* c in channels) {
		if (c.isChannel && c.config.autoJoin) {
			[ary addObject:c];
		}
	}
	
	[self joinChannels:ary];
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

- (void)checkRejoin:(IRCChannel*)c
{
	if (![Preferences autoRejoin]) return;
	if (myMode.r) return;
	if (!c || !c.isChannel || c.isOp || [c numberOfMembers] > 1 || c.mode.a) return;
	if (![c.name isModeChannelName]) return;
	
	NSString* pass = c.mode.k;
	if (!pass.length) pass = nil;
	
	NSString* topic = c.topic;
	if (!topic.length) topic = nil;
	
	[self partChannel:c];
	c.storedTopic = topic;
	[self joinChannel:c password:pass];
}

#pragma mark -
#pragma mark Sending Text

- (BOOL)inputText:(NSString*)str command:(NSString*)command
{
	if (!isConnected) return NO;
	
	id sel = world.selected;
	if (!sel) return NO;
	
	NSArray* lines = [str splitIntoLines];
	for (NSString* s in lines) {
		if (s.length == 0) continue;
		
		if ([sel isClient]) {
			// server
			if ([s hasPrefix:@"/"]) {
				s = [s substringFromIndex:1];
			}
			[self sendCommand:s];
		}
		else {
			// channel
			IRCChannel* channel = (IRCChannel*)sel;
			
			if ([s hasPrefix:@"/"] && ![s hasPrefix:@"//"]) {
				// command
				s = [s substringFromIndex:1];
				[self sendCommand:s];
			}
			else {
				// text
				if ([s hasPrefix:@"/"]) {
					s = [s substringFromIndex:1];
				}
				[self sendText:s command:command channel:channel];
			}
		}
	}
	
	return YES;
}

- (NSString*)truncateText:(NSMutableString*)str command:(NSString*)command channelName:(NSString*)chname
{
	int max = IRC_BODY_LEN;
	
	if (chname) {
		max -= [conn convertToCommonEncoding:chname].length;
	}
	
	if (myNick.length) {
		max -= myNick.length;
	}
	else {
		max -= isupport.nickLen;
	}
	
	max -= config.username.length;
	
	if (joinMyAddress) {
		max -= joinMyAddress.length;
	}
	else {
		max -= IRC_ADDRESS_LEN;
	}
	
	if ([command isEqualToString:NOTICE]) {
		max -= 18;
	}
	else if ([command isEqualToString:ACTION]) {
		max -= 28;
	}
	else {
		max -= 19;
	}
	
	if (max <= 0) {
		return nil;
	}
	
	NSString* s = str;
	if (s.length > max) {
		s = [s substringToIndex:max];
	}
	else {
		s = [[s copy] autorelease];
	}
	
	while (1) {
		int len = [conn convertToCommonEncoding:s].length;
		int delta = len - max;
		if (delta <= 0) break;
		
		// for faster convergence
		if (delta < 5) {
			s = [s substringToIndex:s.length - 1];
		}
		else {
			s = [s substringToIndex:s.length - (delta / 3)];
		}
	}
	
	[str deleteCharactersInRange:NSMakeRange(0, s.length)];
	return s;
}

- (void)sendText:(NSString*)str command:(NSString*)command channel:(IRCChannel*)channel
{
	if (!str.length) return;
	
	LogLineType type;
	if ([command isEqualToString:NOTICE]) {
		type = LINE_TYPE_NOTICE;
	}
	else if ([command isEqualToString:ACTION]) {
		type = LINE_TYPE_ACTION;
	}
	else {
		type = LINE_TYPE_PRIVMSG;
	}
	
	NSArray* lines = [str splitIntoLines];
	for (NSString* line in lines) {
		if (!line.length) continue;
		
		NSMutableString* s = [[line mutableCopy] autorelease];
		
		while (s.length > 0) {
			NSString* t = [self truncateText:s command:command channelName:channel.name];
			if (!t.length) break;
			
			[self printBoth:channel type:type nick:myNick text:t identified:YES];
			
			NSString* cmd = command;
			if (type == LINE_TYPE_ACTION) {
				cmd = PRIVMSG;
				t = [NSString stringWithFormat:@"\x01%@ %@\x01", ACTION, t];
			}
			[self send:cmd, channel.name, t, nil];
		}
		
		if ([command isEqualToString:PRIVMSG]) {
			NSString* recipientNick = nil;
			
			static OnigRegexp* headPattern = nil;
			static OnigRegexp* tailPattern = nil;
			static OnigRegexp* twitterPattern = nil;
			
			if (!headPattern) {
				headPattern = [[OnigRegexp compile:@"^([^\\s:]+):\\s?"] retain];
			}
			if (!tailPattern) {
				tailPattern = [[OnigRegexp compile:@"[>＞]\\s?([^\\s]+)$"] retain];
			}
			if (!twitterPattern) {
				twitterPattern = [[OnigRegexp compile:@"^@([0-9a-zA-Z_]+)\\s"] retain];
			}
			
			OnigResult* result;
			
			result = [headPattern search:line];
			if (result) {
				recipientNick = [line substringWithRange:[result rangeAt:1]];
			}
			else {
				result = [tailPattern search:line];
				if (result) {
					recipientNick = [line substringWithRange:[result rangeAt:1]];
				}
				else {
					result = [twitterPattern search:line];
					if (result) {
						recipientNick = [line substringWithRange:[result rangeAt:1]];
					}
				}
			}
			
			if (recipientNick) {
				IRCUser* recipient = [channel findMember:recipientNick];
				if (recipient) {
					[recipient incomingConversation];
				}
			}
		}
	}
}

- (void)sendCTCPQuery:(NSString*)target command:(NSString*)command text:(NSString*)text
{
	NSString* trail;
	if (text.length) {
		trail = [NSString stringWithFormat:@"\x01%@ %@\x01", command, text];
	}
	else {
		trail = [NSString stringWithFormat:@"\x01%@\x01", command];
	}
	[self send:PRIVMSG, target, trail, nil];
}

- (void)sendCTCPReply:(NSString*)target command:(NSString*)command text:(NSString*)text
{
	NSString* trail;
	if (text.length) {
		trail = [NSString stringWithFormat:@"\x01%@ %@\x01", command, text];
	}
	else {
		trail = [NSString stringWithFormat:@"\x01%@\x01", command];
	}
	[self send:NOTICE, target, trail, nil];
}

- (void)sendCTCPPing:(NSString*)target
{
	[self sendCTCPQuery:target command:PING text:[NSString stringWithFormat:@"%f", CFAbsoluteTimeGetCurrent()]];
}

- (NSString*)expandVariables:(NSString*)s
{
	return [s stringByReplacingOccurrencesOfString:@"$nick" withString:myNick];
}

- (BOOL)sendCommand:(NSString*)s
{
	return [self sendCommand:s completeTarget:YES target:nil];
}

- (BOOL)sendCommand:(NSString*)str completeTarget:(BOOL)completeTarget target:(NSString*)targetChannelName
{
	if (!isConnected || !str.length) return NO;
	
	str = [self expandVariables:str];
	
	NSMutableString* s = [[str mutableCopy] autorelease];
	
	NSString* cmd = [[s getToken] uppercaseString];
	if (!cmd.length) return NO;

	IRCClient* u = world.selectedClient;
	IRCChannel* c = world.selectedChannel;
	
	IRCChannel* selChannel = nil;
	if ([cmd isEqualToString:MODE] && !([s hasPrefix:@"+"] || [s hasPrefix:@"-"])) {
		// do not complete for /mode #chname ...
	}
	else if (completeTarget && targetChannelName) {
		selChannel = [self findChannel:targetChannelName];
	}
	else if (completeTarget && u == self && c) {
		selChannel = c;
	}
	
	//
	// parse pseudo commands and aliases
	//
	
	BOOL opMsg = NO;
	
	if ([cmd isEqualToString:CLEAR]) {
		if (c) {
			[c.log clear];
		}
		else if (u) {
			[u.log clear];
		}
		return YES;
	}
	else if ([cmd isEqualToString:WEIGHTS]) {
		if (c) {
			[self printBoth:nil type:LINE_TYPE_REPLY text:@"WEIGHTS: "];
			for (IRCUser* m in c.members) {
				if (m.weight > 0) {
					NSString* text = [NSString stringWithFormat:@"%@ - sent: %f receive: %f total: %f", m.nick, m.incomingWeight, m.outgoingWeight, m.weight];
					[self printBoth:nil type:LINE_TYPE_REPLY text:text];
				}
			}
		}
		return YES;
	}
	else if ([cmd isEqualToString:QUERY]) {
		NSString* nick = [s getToken];
		if (!nick.length) {
			// close the current talk
			if (c && c.isTalk) {
				[world destroyChannel:c];
			}
		}
		else {
			// open a new talk
			IRCChannel* c = [self findChannel:nick];
			if (!c) {
				c = [world createTalk:nick client:self];
			}
			[world select:c];
		}
		return YES;
	}
	else if ([cmd isEqualToString:CLOSE]) {
		NSString* nick = [s getToken];
		if (nick.length) {
			c = [self findChannel:nick];
		}
		if (c && c.isTalk) {
			[world destroyChannel:c];
		}
		return YES;
	}
	else if ([cmd isEqualToString:TIMER]) {
		int interval = [[s getToken] intValue];
		if (interval > 0) {
			TimerCommand* cmd = [[TimerCommand new] autorelease];
			if ([s hasPrefix:@"/"]) {
				[s deleteCharactersInRange:NSMakeRange(0, 1)];
			}
			cmd.input = s;
			cmd.time = CFAbsoluteTimeGetCurrent() + interval;
			cmd.cid = c ? c.uid : -1;
			[self addCommandToCommandQueue:cmd];
		}
		else {
			[self printBoth:nil type:LINE_TYPE_ERROR_REPLY text:@"timer command needs interval as a number"];
		}
		return YES;
	}
	else if ([cmd isEqualToString:REJOIN] || [cmd isEqualToString:HOP] || [cmd isEqualToString:CYCLE]) {
		if (c) {
			NSString* pass = c.mode.k;
			if (!pass.length) pass = nil;
			[self partChannel:c];
			[self joinChannel:c password:pass];
		}
		return YES;
	}
	else if ([cmd isEqualToString:OMSG]) {
		opMsg = YES;
		cmd = PRIVMSG;
	}
	else if ([cmd isEqualToString:ONOTICE]) {
		opMsg = YES;
		cmd = NOTICE;
	}
	else if ([cmd isEqualToString:MSG] || [cmd isEqualToString:M]) {
		cmd = PRIVMSG;
	}
	else if ([cmd isEqualToString:LEAVE]) {
		cmd = PART;
	}
	else if ([cmd isEqualToString:J]) {
		cmd = JOIN;
	}
	else if ([cmd isEqualToString:T]) {
		cmd = TOPIC;
	}
	else if ([cmd isEqualToString:IGNORE] || [cmd isEqualToString:UNIGNORE]) {
		if (!s.length) {
			[world.menuController showServerPropertyDialog:self ignore:YES];
			return YES;
		}
		
		BOOL useNick = NO;
		BOOL useText = NO;
		
		if ([s hasPrefix:@"-"]) {
			NSString* options = [s getToken];
			useNick = [options contains:@"n"];
			useText = [options contains:@"m"];
		}

		if (!useNick && !useText) {
			useNick = YES;
		}
		
		NSString* nick = nil;
		NSString* text = nil;
		BOOL useRegexForNick = NO;
		BOOL useRegexForText = NO;
		NSMutableArray* chnames = [NSMutableArray array];
		
		if (useNick) {
			nick = [s getIgnoreToken];
			if (nick.length > 2) {
				if ([nick hasPrefix:@"/"] && [nick hasSuffix:@"/"]) {
					useRegexForNick = YES;
					nick = [nick substringWithRange:NSMakeRange(1, nick.length-2)];
				}
			}
		}
		
		if (useText) {
			text = [s getIgnoreToken];
			if (text.length) {
				if ([text hasPrefix:@"/"] && [text hasSuffix:@"/"]) {
					useRegexForText = YES;
					text = [text substringWithRange:NSMakeRange(1, text.length-2)];
				}
				else if ([text hasPrefix:@"\""] && [text hasSuffix:@"\""]) {
					text = [text substringWithRange:NSMakeRange(1, text.length-2)];
				}
			}
		}
		
		while (s.length) {
			NSString* chname = [s getToken];
			if (chname.length) {
				[chnames addObject:chname];
			}
		}
		
		IgnoreItem* g = [[IgnoreItem new] autorelease];
		g.nick = nick;
		g.text = text;
		g.useRegexForNick = useRegexForNick;
		g.useRegexForText = useRegexForText;
		g.channels = chnames;
		
		if (g.isValid) {
			if ([cmd isEqualToString:IGNORE]) {
				BOOL found = NO;
				for (IgnoreItem* e in config.ignores) {
					if ([g isEqual:e]) {
						found = YES;
						break;
					}
				}
				
				if (!found) {
					[config.ignores addObject:g];
					[world save];
				}
			}
			else {
				NSMutableArray* ignores = config.ignores;
				for (int i=ignores.count-1; i>=0; --i) {
					IgnoreItem* e = [ignores objectAtIndex:i];
					if ([g isEqual:e]) {
						[ignores removeObjectAtIndex:i];
						[world save];
						break;
					}
				}
			}
		}
		
		return YES;
	}
	else if ([cmd isEqualToString:RAW] || [cmd isEqualToString:QUOTE]) {
		[self sendLine:s];
		return YES;
	}
	
	//
	// get target if needed
	//
	
	if ([cmd isEqualToString:PRIVMSG] || [cmd isEqualToString:NOTICE] || [cmd isEqualToString:ACTION]) {
		if (opMsg) {
			if (selChannel && selChannel.isChannel && ![s isChannelName]) {
				targetChannelName = selChannel.name;
			}
			else {
				targetChannelName = [s getToken];
			}
		}
		else {
			targetChannelName = [s getToken];
		}
	}
	else if ([cmd isEqualToString:ME]) {
		cmd = ACTION;
		if (selChannel) {
			targetChannelName = selChannel.name;
		}
		else {
			targetChannelName = [s getToken];
		}
	}
	else if ([cmd isEqualToString:PART]) {
		if (selChannel && selChannel.isChannel && ![s isChannelName]) {
			targetChannelName = selChannel.name;
		}
		else if (selChannel && selChannel.isTalk && ![s isChannelName]) {
			[world destroyChannel:selChannel];
			return YES;
		}
		else {
			targetChannelName = [s getToken];
		}
	}
	else if ([cmd isEqualToString:TOPIC]) {
		if (selChannel && selChannel.isChannel && ![s isChannelName]) {
			targetChannelName = selChannel.name;
		}
		else {
			targetChannelName = [s getToken];
		}
	}
	else if ([cmd isEqualToString:MODE]) {
		if (selChannel && selChannel.isChannel && ![s isModeChannelName]) {
			targetChannelName = selChannel.name;
		}
		else if (!([s hasPrefix:@"+"] || [s hasPrefix:@"-"])) {
			targetChannelName = [s getToken];
		}
	}
	else if ([cmd isEqualToString:KICK]) {
		if (selChannel && selChannel.isChannel && ![s isModeChannelName]) {
			targetChannelName = selChannel.name;
		}
		else {
			targetChannelName = [s getToken];
		}
	}
	else if ([cmd isEqualToString:JOIN]) {
		if (selChannel && selChannel.isChannel && !s.length) {
			targetChannelName = selChannel.name;
		}
		else {
			targetChannelName = [s getToken];
			if (![targetChannelName isChannelName]) {
				targetChannelName = [@"#" stringByAppendingString:targetChannelName];
			}
		}
	}
	else if ([cmd isEqualToString:INVITE]) {
		targetChannelName = [s getToken];
	}
	else if ([cmd isEqualToString:OP]
			 || [cmd isEqualToString:DEOP]
			 || [cmd isEqualToString:HALFOP]
			 || [cmd isEqualToString:DEHALFOP]
			 || [cmd isEqualToString:VOICE]
			 || [cmd isEqualToString:DEVOICE]
			 || [cmd isEqualToString:BAN]
			 || [cmd isEqualToString:UNBAN]) {
		if (selChannel && selChannel.isChannel && ![s isModeChannelName]) {
			targetChannelName = selChannel.name;
		}
		else {
			targetChannelName = [s getToken];
		}
		
		NSString* sign;
		if ([cmd hasPrefix:@"DE"] || [cmd hasPrefix:@"UN"]) {
			sign = @"-";
			cmd = [cmd substringFromIndex:2];
		}
		else {
			sign = @"+";
		}
		
		NSArray* params = [s componentsSeparatedByString:@" "];
		if (!params.count) {
			if ([cmd isEqualToString:BAN]) {
				[s setString:@"+b"];
			}
			else {
				return YES;
			}
		}
		else {
			NSMutableString* ms = [NSMutableString stringWithString:sign];
			NSString* modeCharStr = [[cmd substringToIndex:1] lowercaseString];
			for (int i=params.count-1; i>=0; --i) {
				[ms appendString:modeCharStr];
			}
			[ms appendString:@" "];
			[ms appendString:s];
			[s setString:ms];
		}
		
		cmd = MODE;
	}
	else if ([cmd isEqualToString:UMODE]) {
		cmd = MODE;
		[s insertString:@" " atIndex:0];
		[s insertString:myNick atIndex:0];
	}
	
	//
	// cut colon
	//
	
	BOOL cutColon = NO;
	if ([s hasPrefix:@"/"]) {
		cutColon = YES;
		[s deleteCharactersInRange:NSMakeRange(0, 1)];
	}
	
	//
	// process text commands
	//
	
	if ([cmd isEqualToString:PRIVMSG] || [cmd isEqualToString:NOTICE]) {
		if ([s hasPrefix:@"\x01"]) {
			// CTCP
			cmd = [cmd isEqualToString:PRIVMSG] ? CTCP : CTCPREPLY;
			[s deleteCharactersInRange:NSMakeRange(0, 1)];
			NSRange r = [s rangeOfString:@"\x01"];
			if (r.location != NSNotFound) {
				int len = s.length - r.location;
				if (len > 0) {
					[s deleteCharactersInRange:NSMakeRange(r.location, len)];
				}
			}
		}
	}
	
	if ([cmd isEqualToString:CTCP]) {
		NSMutableString* t = [[s mutableCopy] autorelease];
		NSString* subCommand = [[t getToken] uppercaseString];
		if ([subCommand isEqualToString:ACTION]) {
			cmd = ACTION;
			s = t;
			targetChannelName = [s getToken];
		}
	}
	
	//
	// finally action
	//
	
	if ([cmd isEqualToString:PRIVMSG] || [cmd isEqualToString:NOTICE] || [cmd isEqualToString:ACTION]) {
		if (!targetChannelName) return NO;
		if (!s.length) return NO;
		
		LogLineType type;
		if ([cmd isEqualToString:NOTICE]) {
			type = LINE_TYPE_NOTICE;
		}
		else if ([cmd isEqualToString:ACTION]) {
			type = LINE_TYPE_ACTION;
		}
		else {
			type = LINE_TYPE_PRIVMSG;
		}
		
		while (s.length) {
			NSString* t = [self truncateText:s command:cmd channelName:targetChannelName];
			if (!t.length) break;
			
			NSMutableArray* targetsResult = [NSMutableArray array];
			NSArray* targets = [targetChannelName componentsSeparatedByString:@","];
			for (NSString* chname in targets) {
				if (!chname.length) continue;
				
				// support @#channel
				BOOL opPrefix = NO;
				if ([chname hasPrefix:@"@"]) {
					opPrefix = YES;
					chname = [chname substringFromIndex:1];
				}
				
				NSString* lowerChname = [chname lowercaseString];
				IRCChannel* c = [self findChannel:chname];
				
				if (!c
					&& ![chname isChannelName]
					&& ![lowerChname isEqualToString:@"nickserv"]
					&& ![lowerChname isEqualToString:@"chanserv"]) {
					c = [world createTalk:chname client:self];
				}
				
				[self printBoth:(c ?: (id)chname) type:type nick:myNick text:t identified:YES];
				
				// support @#channel and omsg/onotice
				if ([chname isChannelName]) {
					if (opMsg || opPrefix) {
						chname = [@"@" stringByAppendingString:chname];
					}
				}
				
				[targetsResult addObject:chname];
			}
			
			NSString* localCmd = cmd;
			if ([localCmd isEqualToString:ACTION]) {
				localCmd = PRIVMSG;
				t = [NSString stringWithFormat:@"\x01%@ %@\x01", ACTION, t];
			}
			
			[self send:localCmd, [targetsResult componentsJoinedByString:@","], t, nil];
		}
	}
	else if ([cmd isEqualToString:CTCP]) {
		NSString* subCommand = [[s getToken] uppercaseString];
		if (subCommand.length) {
			targetChannelName = [s getToken];
			if ([subCommand isEqualToString:PING]) {
				[self sendCTCPPing:targetChannelName];
			}
			else {
				[self sendCTCPQuery:targetChannelName command:subCommand text:s];
			}
		}
	}
	else if ([cmd isEqualToString:CTCPREPLY]) {
		targetChannelName = [s getToken];
		NSString* subCommand = [s getToken];
		[self sendCTCPReply:targetChannelName command:subCommand text:s];
	}
	else if ([cmd isEqualToString:QUIT]) {
		[self quit:s];
	}
	else if ([cmd isEqualToString:NICK]) {
		[self changeNick:[s getToken]];
	}
	else if ([cmd isEqualToString:TOPIC]) {
		if (!s.length && !cutColon) {
			s = nil;
		}
		[self send:cmd, targetChannelName, s, nil];
	}
	else if ([cmd isEqualToString:PART]) {
		if (!s.length && !cutColon) {
			s = nil;
		}
		[self send:cmd, targetChannelName, s, nil];
	}
	else if ([cmd isEqualToString:KICK]) {
		NSString* peer = [s getToken];
		[self send:cmd, targetChannelName, peer, s, nil];
	}
	else if ([cmd isEqualToString:AWAY]) {
		if (!s.length && !cutColon) {
			s = nil;
		}
		[self send:cmd, s, nil];
	}
	else if ([cmd isEqualToString:JOIN] || [cmd isEqualToString:INVITE]) {
		if (!s.length && !cutColon) {
			s = nil;
		}
		[self send:cmd, targetChannelName, s, nil];
	}
	else if ([cmd isEqualToString:MODE]) {
		NSMutableString* line = [NSMutableString string];
		[line appendString:MODE];
		if (targetChannelName.length) {
			[line appendString:@" "];
			[line appendString:targetChannelName];
		}
		if (s.length) {
			[line appendString:@" "];
			[line appendString:s];
		}
		[self sendLine:line];
	}
	else if ([cmd isEqualToString:WHOIS]) {
		if ([s contains:@" "]) {
			[self sendLine:[NSString stringWithFormat:@"%@ %@", WHOIS, s]];
		}
		else {
			[self send:WHOIS, s, s, nil];
		}
	}
	else {
		if (cutColon) {
			[s insertString:@":" atIndex:0];
		}
		[s insertString:@" " atIndex:0];
		[s insertString:cmd atIndex:0];
		[self sendLine:s];
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

#pragma mark -
#pragma mark Find Channel

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

#pragma mark -
#pragma mark Command Queue

- (void)processCommandsInCommandQueue
{
	CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
	
	while (commandQueue.count) {
		TimerCommand* m = [commandQueue objectAtIndex:0];
		if (m.time <= now) {
			NSString* target = nil;
			IRCChannel* c = [world findChannelByClientId:uid channelId:m.cid];
			if (c) {
				target = c.name;
			}
			
			[self sendCommand:m.input completeTarget:YES target:target];
			
			[commandQueue removeObjectAtIndex:0];
		}
		else {
			break;
		}
	}
	
	if (commandQueue.count) {
		TimerCommand* m = [commandQueue objectAtIndex:0];
		CFAbsoluteTime delta = m.time - CFAbsoluteTimeGetCurrent();
		[commandQueueTimer start:delta];
	}
	else {
		[commandQueueTimer stop];
	}
}

- (void)addCommandToCommandQueue:(TimerCommand*)m
{
	BOOL added = NO;
	int i = 0;
	for (TimerCommand* c in commandQueue) {
		if (m.time < c.time) {
			added = YES;
			[commandQueue insertObject:m atIndex:i];
			break;
		}
		++i;
	}
	
	if (!added) {
		[commandQueue addObject:m];
	}
	
	if (i == 0) {
		[self processCommandsInCommandQueue];
	}
}

- (void)clearCommandQueue
{
	[commandQueueTimer stop];
	[commandQueue removeAllObjects];
}

- (void)onCommandQueueTimer:(id)sender
{
	[self processCommandsInCommandQueue];
}

#pragma mark -
#pragma mark Window Title

- (void)updateClientTitle
{
	[world updateClientTitle:self];
}

- (void)updateChannelTitle:(IRCChannel*)c
{
	[world updateChannelTitle:c];
}

#pragma mark -
#pragma mark Growl

- (void)notifyText:(GrowlNotificationType)type target:(id)target nick:(NSString*)nick text:(NSString*)text
{
	if ([Preferences stopGrowlOnActive] && [NSApp isActive]) return;
	if (![Preferences growlEnabledForEvent:type]) return;
	
	IRCChannel* channel = nil;
	NSString* chname = nil;
	if (target) {
		if ([target isKindOfClass:[IRCChannel class]]) {
			channel = (IRCChannel*)target;
			chname = channel.name;
			if (!channel.config.growl) {
				return;
			}
		}
		else {
			chname = (NSString*)target;
		}
	}
	if (!chname) {
		chname = self.name;
	}
	
	NSString* title = chname;
	NSString* desc = [NSString stringWithFormat:@"<%@> %@", nick, text];
	NSString* context;
	if (channel) {
		context = [NSString stringWithFormat:@"%d %d", uid, channel.uid];
	}
	else {
		context = [NSString stringWithFormat:@"%d", uid];
	}
	
	[world notifyOnGrowl:type title:title desc:desc context:context];
}

- (void)notifyEvent:(GrowlNotificationType)type
{
	[self notifyEvent:type target:nil nick:@"" text:@""];
}

- (void)notifyEvent:(GrowlNotificationType)type target:(id)target nick:(NSString*)nick text:(NSString*)text
{
	if ([Preferences stopGrowlOnActive] && [NSApp isActive]) return;
	if (![Preferences growlEnabledForEvent:type]) return;
	
	IRCChannel* channel = nil;
	NSString* chname = nil;
	if (target) {
		if ([target isKindOfClass:[IRCChannel class]]) {
			channel = (IRCChannel*)target;
			chname = channel.name;
			if (!channel.config.growl) {
				return;
			}
		}
		else {
			chname = (NSString*)target;
		}
	}
	if (!chname) {
		chname = self.name;
	}
	
	NSString* title = @"";
	NSString* desc = @"";
	
	switch (type) {
		case GROWL_LOGIN:
			title = self.name;
			break;
		case GROWL_DISCONNECT:
			title = self.name;
			break;
		case GROWL_KICKED:
			title = channel.name;
			desc = [NSString stringWithFormat:@"%@ has kicked out you : %@", nick, text];
			break;
		case GROWL_INVITED:
			title = self.name;
			desc = [NSString stringWithFormat:@"%@ has invited you to %@", nick, text];
			break;
		default:
			return;
	}
	
	NSString* context;
	if (channel) {
		context = [NSString stringWithFormat:@"%d %d", uid, channel.uid];
	}
	else {
		context = [NSString stringWithFormat:@"%d", uid];
	}
	
	[world notifyOnGrowl:type title:title desc:desc context:context];
}

#pragma mark -
#pragma mark Channel States

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
	NSString* format = @"%H:%M";
	if ([Preferences themeOverrideTimestampFormat]) {
		format = [Preferences themeTimestampFormat];
	}
	
	time_t global = time(NULL);
	struct tm* local = localtime(&global);
	char buf[TIME_BUFFER_SIZE+1];
	strftime(buf, TIME_BUFFER_SIZE, [format UTF8String], local);
	buf[TIME_BUFFER_SIZE] = 0;
	NSString* result = [[[NSString alloc] initWithBytes:buf length:strlen(buf) encoding:NSUTF8StringEncoding] autorelease];
	return result;
}

- (BOOL)needPrintConsole:(id)chan
{
	if (!chan) chan = self;
	
	IRCTreeItem* target = self;
	IRCChannel* channel = nil;
	if ([chan isKindOfClass:[IRCChannel class]]) {
		channel = (IRCChannel*)chan;
		target = channel;
	}
	
	if (channel && !channel.config.logToConsole) {
		return NO;
	}
	
	return target != world.selected || !target.log.viewingBottom;
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

- (NSString*)formatNick:(NSString*)nick channel:(IRCChannel*)channel
{
	NSString* format;
	if ([Preferences themeOverrideNickFormat]) {
		format = [Preferences themeNickFormat];
	}
	else {
		format = world.viewTheme.other.logNickFormat;
	}
	
	NSString* s = format;
	
	if ([s contains:@"%@"]) {
		char mark = ' ';
		if (channel && !channel.isClient && channel.isChannel) {
			IRCUser* m = [channel findMember:nick];
			if (m) {
				mark = m.mark;
			}
		}
		s = [s stringByReplacingOccurrencesOfString:@"%@" withString:[NSString stringWithFormat:@"%c", mark]];
	}
	
	static OnigRegexp* nickPattern = nil;
	if (!nickPattern) {
		nickPattern = [[OnigRegexp compile:@"%(-?\\d+)?n"] retain];
	}
	
	while (1) {
		OnigResult* result = [nickPattern search:s];
		if (!result) break;
		
		NSRange r = result.bodyRange;
		NSRange numRange = [result rangeAt:1];
		
		if (numRange.location != NSNotFound && numRange.length > 0) {
			NSString* numStr = [s substringWithRange:numRange];
			int n = [numStr intValue];
			
			NSString* formattedNick = nick;
			if (n >= 0) {
				int pad = n - nick.length;
				if (pad > 0) {
					NSMutableString* ms = [NSMutableString stringWithString:nick];
					for (int i=0; i<pad; ++i) {
						[ms appendString:@" "];
					}
					formattedNick = ms;
				}
			}
			else {
				int pad = -n - nick.length;
				if (pad > 0) {
					NSMutableString* ms = [NSMutableString string];
					for (int i=0; i<pad; ++i) {
						[ms appendString:@" "];
					}
					[ms appendString:nick];
					formattedNick = ms;
				}
			}
			s = [s stringByReplacingCharactersInRange:r withString:formattedNick];
		}
		else {
			s = [s stringByReplacingCharactersInRange:r withString:nick];
		}
	}
	
	return s;
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
	NSArray* keywords = nil;
	NSArray* excludeWords = nil;

	if (time.length) {
		time = [time stringByAppendingString:@" "];
	}
	
	if ([chan isKindOfClass:[IRCChannel class]]) {
		channel = chan;
		channelName = channel.name;
	}
	else if ([chan isKindOfClass:[NSString class]]) {
		channelName = chan;
	}
	
	if (channelName && [channelName isChannelName]) {
		place = [NSString stringWithFormat:@"<%@> ", channelName];
	}
	else {
		place = [NSString stringWithFormat:@"<%@> ", config.name];
	}
	
	if (nick.length > 0) {
		if (type == LINE_TYPE_ACTION) {
			nickStr = [NSString stringWithFormat:@"%@ ", nick];
		}
		else {
			nickStr = [self formatNick:nick channel:channel];
		}
	}
	
	if (nick && [nick isEqualToString:myNick]) {
		memberType = MEMBER_TYPE_MYSELF;
	}
	
	if (nick && channel) {
		IRCUser* user = [channel findMember:nick];
		if (user) {
			colorNumber = user.colorNumber;
		}
	}
	
	if (channel) {
		clickContext = [NSString stringWithFormat:@"channel %d %d", uid, channel.uid];
	}
	else {
		clickContext = [NSString stringWithFormat:@"client %d", uid];
	}
	
	if (type == LINE_TYPE_PRIVMSG || type == LINE_TYPE_ACTION) {
		if (memberType != MEMBER_TYPE_MYSELF) {
			keywords = [Preferences keywords];
			excludeWords = [Preferences excludeWords];
			
			if ([Preferences keywordCurrentNick]) {
				NSMutableArray* ary = [[keywords mutableCopy] autorelease];
				[ary insertObject:myNick atIndex:0];
				keywords = ary;
			}
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
	c.clickInfo = clickContext;
	c.identified = identified;
	c.nickColorNumber = colorNumber;
	c.keywords = keywords;
	c.excludeWords = excludeWords;

	[world.consoleLog print:c];
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
	NSArray* keywords = nil;
	NSArray* excludeWords = nil;

	if (time.length) {
		time = [time stringByAppendingString:@" "];
	}
	
	if ([chan isKindOfClass:[IRCChannel class]]) {
		channel = chan;
		channelName = channel.name;
	}
	else if ([chan isKindOfClass:[NSString class]]) {
		channelName = chan;
		place = [NSString stringWithFormat:@"<%@> ", channelName];
	}
	
	if (nick.length > 0) {
		if (type == LINE_TYPE_ACTION) {
			nickStr = [NSString stringWithFormat:@"%@ ", nick];
		}
		else {
			nickStr = [self formatNick:nick channel:channel];
		}
	}
	
	if (nick && [nick isEqualToString:myNick]) {
		memberType = MEMBER_TYPE_MYSELF;
	}
	
	if (nick && channel) {
		IRCUser* user = [channel findMember:nick];
		if (user) {
			colorNumber = user.colorNumber;
		}
	}
	
	if (type == LINE_TYPE_PRIVMSG || type == LINE_TYPE_ACTION) {
		if (memberType != MEMBER_TYPE_MYSELF) {
			keywords = [Preferences keywords];
			excludeWords = [Preferences excludeWords];
			
			if ([Preferences keywordCurrentNick]) {
				NSMutableArray* ary = [[keywords mutableCopy] autorelease];
				[ary insertObject:myNick atIndex:0];
				keywords = ary;
			}
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
	c.keywords = keywords;
	c.excludeWords = excludeWords;
	c.useAvatar = type == LINE_TYPE_PRIVMSG && [config.userInfo contains:@"showTwitterAvatar"];
	
	if (channel) {
		return [channel print:c];
	}
	else {
		return [log print:c];
	}
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
	[self printBoth:nil type:LINE_TYPE_REPLY text:text];
}

- (void)printUnknownReply:(IRCMessage*)m
{
	NSString* text = [NSString stringWithFormat:@"Reply(%d): %@", m.numericReply, [m sequence:1]];
	[self printBoth:nil type:LINE_TYPE_REPLY text:text];
}

- (void)printErrorReply:(IRCMessage*)m
{
	[self printErrorReply:m channel:nil];
}

- (void)printErrorReply:(IRCMessage*)m channel:(IRCChannel*)channel
{
	NSString* text = [NSString stringWithFormat:@"Error(%d): %@", m.numericReply, [m sequence:1]];
	[self printBoth:channel type:LINE_TYPE_ERROR_REPLY text:text];
}

- (void)printError:(NSString*)error
{
	[self printBoth:nil type:LINE_TYPE_ERROR text:error];
}

#pragma mark -
#pragma mark IRCTreeItem

- (BOOL)isClient
{
	return YES;
}

- (BOOL)isActive
{
	return isLoggedIn;
}

- (IRCClient*)client
{
	return self;
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
#pragma mark WhoisDialog

- (WhoisDialog*)createWhoisDialogWithNick:(NSString*)nick username:(NSString*)username address:(NSString*)address realname:(NSString*)realname
{
	WhoisDialog* d = [self findWhoisDialog:nick];
	if (d) {
		[d show];
		return d;
	}
	
	d = [[WhoisDialog new] autorelease];
	d.delegate = self;
	[whoisDialogs addObject:d];
	[d startWithNick:nick username:username address:address realname:realname];
	return d;
}

- (WhoisDialog*)findWhoisDialog:(NSString*)nick
{
	for (WhoisDialog* d in whoisDialogs) {
		if ([nick isEqualNoCase:d.nick]) {
			return d;
		}
	}
	return nil;
}

- (void)whoisDialogOnTalk:(WhoisDialog*)sender
{
	IRCChannel* c = [world createTalk:sender.nick client:self];
	if (c) {
		[world select:c];
	}
}

- (void)whoisDialogOnUpdate:(WhoisDialog*)sender
{
	[self sendWhois:sender.nick];
}

- (void)whoisDialogOnJoin:(WhoisDialog*)sender channel:(NSString*)channel
{
	[self send:JOIN, channel, nil];
}

- (void)whoisDialogWillClose:(WhoisDialog*)sender
{
	[[sender retain] autorelease];
	[whoisDialogs removeObjectIdenticalTo:sender];
}

#pragma mark -
#pragma mark HostResolver Delegate

- (void)hostResolver:(HostResolver*)sender didResolve:(NSHost*)host
{
	NSArray* addresses = [host addresses];
	if (addresses.count) {
		NSString* address = [addresses objectAtIndex:0];
		[myAddress release];
		myAddress = [address retain];
	}
}

- (void)hostResolver:(HostResolver*)sender didNotResolve:(NSString*)hostname
{
}

#pragma mark -
#pragma mark Protocol Handlers

- (void)receivePrivmsgAndNotice:(IRCMessage*)m
{
	NSString* text = [m paramAt:1];
	
	BOOL identified = NO;
	if (identifyCTCP && ([text hasPrefix:@"+\x01"] || [text hasPrefix:@"-\x01"])) {
		identified = [text hasPrefix:@"+"];
		text = [text substringFromIndex:1];
	}
	else if (identifyMsg && ([text hasPrefix:@"+"] || [text hasPrefix:@"-"])) {
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
	
	if ([self checkIgnore:text nick:nick channel:target]) {
		return;
	}
	
	if (target.isChannelName) {
		// channel
		IRCChannel* c = [self findChannel:target];
		BOOL keyword = [self printBoth:(c ?: (id)target) type:type nick:nick text:text identified:identified];

		if (type == LINE_TYPE_NOTICE) {
			[self notifyText:GROWL_CHANNEL_NOTICE target:(c ?: (id)target) nick:nick text:text];
			[SoundPlayer play:[Preferences soundForEvent:GROWL_CHANNEL_NOTICE]];
		}
		else {
			id t = c ?: (id)self;
			[self setUnreadState:t];
			if (keyword) [self setKeywordState:t];
			
			GrowlNotificationType kind = keyword ? GROWL_HIGHLIGHT : GROWL_CHANNEL_MSG;
			[self notifyText:kind target:(c ?: (id)target) nick:nick text:text];
			[SoundPlayer play:[Preferences soundForEvent:kind]];
			
			if (c) {
				// track the conversation to nick complete
				IRCUser* sender = [c findMember:nick];
				if (sender) {
					static NSCharacterSet* underlineSet = nil;
					if (!underlineSet) {
						underlineSet = [[NSCharacterSet characterSetWithCharactersInString:@"_"] retain];
					}
					NSString* trimmedMyNick = [myNick stringByTrimmingCharactersInSet:underlineSet];
					if ([text rangeOfString:trimmedMyNick options:NSCaseInsensitiveSearch].location != NSNotFound) {
						[sender outgoingConversation];
					}
					else {
						[sender conversation];
					}
				}
			}
		}
	}
	else if ([target isEqualNoCase:myNick]) {
		if (!nick.length || [nick contains:@"."]) {
			// system
			[self printBoth:nil type:type text:text];
		}
		else {
			// talk
			IRCChannel* c = [self findChannel:nick];
			BOOL newTalk = NO;
			if (!c && type != LINE_TYPE_NOTICE) {
				c = [world createTalk:nick client:self];
				newTalk = YES;
			}
			
			BOOL keyword = [self printBoth:c type:type nick:nick text:text identified:identified];
			
			if (type == LINE_TYPE_NOTICE) {
				if ([nick isEqualNoCase:@"NickServ"]) {
					if (registeringToNickServ) {
						if ([text hasPrefix:@"You are now identified for "]
							|| [text hasPrefix:@"Invalid password for "]
							|| [text hasSuffix:@" is not a registered nickname."]) {
							[self performAutoJoin];
						}
					}
					else {
						if ([text hasPrefix:@"This nickname is registered."]) {
							if (config.nickPassword.length) {
								[self send:PRIVMSG, @"NickServ", [NSString stringWithFormat:@"IDENTIFY %@", config.nickPassword], nil];
							}
						}
					}
				}
				
				[self notifyText:GROWL_TALK_NOTICE target:(c ?: (id)target) nick:nick text:text];
				[SoundPlayer play:[Preferences soundForEvent:GROWL_TALK_NOTICE]];
			}
			else {
				id t = c ?: (id)self;
				[self setUnreadState:t];
				if (keyword) [self setKeywordState:t];
				if (newTalk) [self setNewTalkState:t];
				
				GrowlNotificationType kind = keyword ? GROWL_HIGHLIGHT : newTalk ? GROWL_NEW_TALK : GROWL_TALK_MSG;
				[self notifyText:kind target:(c ?: (id)target) nick:nick text:text];
				[SoundPlayer play:[Preferences soundForEvent:kind]];
			}
		}
	}
	else {
		// system
		if (!nick.length || [nick contains:@"."]) {
			[self printBoth:nil type:type text:text];
		}
		else {
			[self printBoth:nil type:type nick:nick text:text identified:identified];
		}
	}
}

- (void)receiveCTCPQuery:(IRCMessage*)m text:(NSString*)text
{
	//LOG(@"CTCP Query: %@", text);
	
	NSString* nick = m.sender.nick;
	NSMutableString* s = [[text mutableCopy] autorelease];
	NSString* command = [[s getToken] uppercaseString];
	
	if ([self checkIgnore:nil nick:nick channel:nil]) {
		return;
	}
	
	if ([command isEqualToString:DCC]) {
		NSString* subCommand = [[s getToken] uppercaseString];
		if ([subCommand isEqualToString:SEND]) {
			NSString* fname;
			if ([s hasPrefix:@"\""]) {
				NSRange r = [s rangeOfString:@"\"" options:0 range:NSMakeRange(1, s.length - 1)];
				if (r.location) {
					fname = [s substringWithRange:NSMakeRange(1, r.location - 1)];
					[s deleteCharactersInRange:NSMakeRange(0, r.location)];
					[s getToken];
				}
				else {
					fname = [s getToken];
				}
			}
			else {
				fname = [s getToken];
			}
			
			NSString* addressStr = [s getToken];
			int port = [[s getToken] intValue];
			long long size = [[s getToken] longLongValue];
			
			[self receiveDCCSend:m fileName:fname address:addressStr port:port fileSize:size];
			return;
		}
		
		NSString* text = [NSString stringWithFormat:@"CTCP-query unknown (DCC %@) from %@ : %@", subCommand, nick, s];
		[self printBoth:nil type:LINE_TYPE_REPLY text:text];
	}
	else {
		CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
		if (now - lastCTCPTime < CTCP_MIN_INTERVAL) {
			NSString* text = [NSString stringWithFormat:@"CTCP-query %@ from %@ was ignored", command, nick];
			[self printBoth:nil type:LINE_TYPE_REPLY text:text];
			return;
		}
		lastCTCPTime = now;
		
		NSString* text = [NSString stringWithFormat:@"CTCP-query %@ from %@", command, nick];
		[self printBoth:nil type:LINE_TYPE_REPLY text:text];
		
		if ([command isEqualToString:PING]) {
			[self sendCTCPReply:nick command:command text:s];
		}
		else if ([command isEqualToString:TIME]) {
			NSString* text = [[NSDate date] description];
			[self sendCTCPReply:nick command:command text:text];
		}
		else if ([command isEqualToString:VERSION]) {
			NSDictionary* info = [[NSBundle mainBundle] infoDictionary];
			NSString* name = [info objectForKey:@"LCApplicationName"];
			NSString* ver = [info objectForKey:@"CFBundleShortVersionString"];
			NSString* text = [NSString stringWithFormat:@"%@ %@", name, ver];
			[self sendCTCPReply:nick command:command text:text];
		}
		else if ([command isEqualToString:USERINFO]) {
			[self sendCTCPReply:nick command:command text:config.userInfo ?: @""];
		}
		else if ([command isEqualToString:CLIENTINFO]) {
			[self sendCTCPReply:nick command:command text:NSLocalizedString(@"CTCPClientInfo", nil)];
		}
	}
}

- (void)receiveCTCPReply:(IRCMessage*)m text:(NSString*)text
{
	NSString* nick = m.sender.nick;
	NSMutableString* s = [[text mutableCopy] autorelease];
	NSString* command = [[s getToken] uppercaseString];
	
	if ([self checkIgnore:nil nick:nick channel:nil]) {
		return;
	}
	
	if ([command isEqualToString:PING]) {
		double time = [s doubleValue];
		double delta = CFAbsoluteTimeGetCurrent() - time;
		
		NSString* text = [NSString stringWithFormat:@"CTCP-reply %@ from %@ : %1.2f sec", command, nick, delta];
		[self printBoth:nil type:LINE_TYPE_REPLY text:text];
	}
	else {
		NSString* text = [NSString stringWithFormat:@"CTCP-reply %@ from %@ : %@", command, nick, s];
		[self printBoth:nil type:LINE_TYPE_REPLY text:text];
	}
}

- (void)receiveDCCSend:(IRCMessage*)m fileName:(NSString*)fileName address:(NSString*)address port:(int)port fileSize:(long long)size
{
	NSString* nick = m.sender.nick;
	NSString* target = [m paramAt:0];
	
	if (![target isEqualToString:myNick]) return;
	
	LOG(@"receive dcc send");
	
	NSString* host;
	if ([address isNumericOnly]) {
		long long a = [address longLongValue];
		int w = a & 0xff; a >>= 8;
		int x = a & 0xff; a >>= 8;
		int y = a & 0xff; a >>= 8;
		int z = a & 0xff;
		host = [NSString stringWithFormat:@"%d.%d.%d.%d", z, y, x, w];
	}
	else {
		host = address;
	}
	
	NSString* text = [NSString stringWithFormat:@"Received file transfer request from %@, %@ (%qi bytes) %@:%d", nick, fileName, size, host, port];
	[self printBoth:nil type:LINE_TYPE_DCC_SEND_RECEIVE text:text];
	
	if ([Preferences dccAction] != DCC_IGNORE) {
		if (port > 0 && size > 0) {
			NSString* path = [@"~/Downloads" stringByExpandingTildeInPath];
			NSFileManager* fm = [NSFileManager defaultManager];
			BOOL isDir = NO;
			if ([fm fileExistsAtPath:path isDirectory:&isDir]) {
				path = @"~/Downloads";
			}
			else {
				path = @"~/Desktop";
			}
			
			[world.dcc addReceiverWithUID:uid nick:nick host:host port:port path:path fileName:fileName size:size];
			
			[self notifyEvent:GROWL_FILE_RECEIVE_REQUEST target:nil nick:nick text:fileName];
			[SoundPlayer play:[Preferences soundForEvent:GROWL_FILE_RECEIVE_REQUEST]];
			
			if (![NSApp isActive]) {
				[NSApp requestUserAttention:NSInformationalRequest];
			}
		}
	}
}

- (void)receiveJoin:(IRCMessage*)m
{
	NSString* nick = m.sender.nick;
	NSString* chname = [m paramAt:0];
	
	BOOL myself = [nick isEqualNoCase:myNick];

	// work around for ircd 2.9.5
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
			c = [world createChannel:seed client:self reload:YES adjust:YES];
			[world save];
		}
		[c activate];
		[self reloadTree];
		[self printSystem:c text:@"You have joined the channel"];
		
		if (!joinMyAddress) {
			joinMyAddress = [m.sender.address retain];
			if (addressDetectionMethod == ADDRESS_DETECT_JOIN) {
				if (joinMyAddress.length) {
					[nameResolver resolve:joinMyAddress];
				}
			}
		}
	}
	
	if (c) {
		IRCUser* u = [[IRCUser new] autorelease];
		u.nick = nick;
		u.username = m.sender.user;
		u.address = m.sender.address;
		u.o = njoin;
		[c addMember:u];
		[self updateChannelTitle:c];
	}
	
	if ([Preferences showJoinLeave]) {
		NSString* text = [NSString stringWithFormat:@"%@ has joined (%@@%@)", nick, m.sender.user, m.sender.address];
		[self printBoth:(c ?: (id)chname) type:LINE_TYPE_JOIN text:text];
	}
	
	//@@@ check auto op
	
	// add user to talk
	c = [self findChannel:nick];
	if (c) {
		IRCUser* u = [[IRCUser new] autorelease];
		u.nick = nick;
		u.username = m.sender.user;
		u.address = m.sender.address;
		[c addMember:u];
	}
}

- (void)receivePart:(IRCMessage*)m
{
	NSString* nick = m.sender.nick;
	NSString* chname = [m paramAt:0];
	NSString* comment = [m paramAt:1];
	
	BOOL myself = NO;
	
	IRCChannel* c = [self findChannel:chname];
	if (c) {
		if ([nick isEqualNoCase:myNick]) {
			myself = YES;
			[c deactivate];
			[self reloadTree];
		}
		[c removeMember:nick];
		[self updateChannelTitle:c];
		
		if (!myself) {
			[self checkRejoin:c];
		}
	}
	
	if ([Preferences showJoinLeave]) {
		NSString* text = [NSString stringWithFormat:@"%@ has left (%@)", nick, comment];
		[self printBoth:(c ?: (id)chname) type:LINE_TYPE_PART text:text];
	}
	
	if (myself) {
		[self printSystem:c text:@"You have left the channel"];
	}
}

- (void)receiveKick:(IRCMessage*)m
{
	NSString* nick = m.sender.nick;
	NSString* chname = [m paramAt:0];
	NSString* target = [m paramAt:1];
	NSString* comment = [m paramAt:2];
	
	IRCChannel* c = [self findChannel:chname];
	if (c) {
		BOOL myself = [target isEqualNoCase:myNick];
		if (myself) {
			[c deactivate];
			[self reloadTree];
			[self printSystemBoth:c text:@"You have been kicked out from the channel"];
			
			[self notifyEvent:GROWL_KICKED target:c nick:nick text:comment];
			[SoundPlayer play:[Preferences soundForEvent:GROWL_KICKED]];
		}
		
		[c removeMember:target];
		[self updateChannelTitle:c];
		[self checkRejoin:c];
	}
	
	NSString* text = [NSString stringWithFormat:@"%@ has kicked %@ (%@)", nick, target, comment];
	[self printBoth:(c ?: (id)chname) type:LINE_TYPE_KICK text:text];
}

- (void)receiveQuit:(IRCMessage*)m
{
	NSString* nick = m.sender.nick;
	NSString* comment = [m paramAt:0];
	
	NSString* text = [NSString stringWithFormat:@"%@ has left IRC (%@)", nick, comment];
	
	for (IRCChannel* c in channels) {
		if ([c findMember:nick]) {
			if ([Preferences showJoinLeave]) {
				[self printChannel:c type:LINE_TYPE_QUIT text:text];
			}
			[c removeMember:nick];
			[self updateChannelTitle:c];
			[self checkRejoin:c];
		}
	}
	
	if ([Preferences showJoinLeave]) {
		[self printConsole:nil type:LINE_TYPE_QUIT text:text];
	}
}

- (void)receiveKill:(IRCMessage*)m
{
	NSString* sender = m.sender.nick;
	if (!sender || !sender.length) {
		sender = m.sender.raw;
	}
	NSString* target = [m paramAt:0];
	NSString* comment = [m paramAt:1];
	
	NSString* text = [NSString stringWithFormat:@"%@ has forced %@ to leave IRC (%@)", sender, target, comment];
	
	for (IRCChannel* c in channels) {
		if ([c findMember:target]) {
			[self printChannel:c type:LINE_TYPE_KILL text:text];
			[c removeMember:target];
			[self updateChannelTitle:c];
			[self checkRejoin:c];
		}
	}
	
	if ([Preferences showJoinLeave]) {
		[self printConsole:nil type:LINE_TYPE_KILL text:text];
	}
}

- (void)receiveNick:(IRCMessage*)m
{
	NSString* nick = m.sender.nick;
	NSString* toNick = [m paramAt:0];
	
	if ([nick isEqualNoCase:myNick]) {
		// changed my nick
		[myNick release];
		myNick = [toNick retain];
		[self updateClientTitle];
		
		NSString* text = [NSString stringWithFormat:@"You are now known as %@", toNick];
		[self printChannel:nil type:LINE_TYPE_NICK text:text];
	}
	
	for (IRCChannel* c in channels) {
		if ([c findMember:nick]) {
			// rename channel member
			NSString* text = [NSString stringWithFormat:@"%@ is now known as %@", nick, toNick];
			[self printChannel:c type:LINE_TYPE_NICK text:text];
			[c renameMember:nick to:toNick];
		}
	}
	
	IRCChannel* c = [self findChannel:nick];
	if (c) {
		IRCChannel* t = [self findChannel:toNick];
		if (t) {
			// there is a channel already for a nick
			// just remove it
			[world destroyChannel:t];
		}
		
		// rename talk
		c.name = toNick;
		[self reloadTree];
		[self updateChannelTitle:c];
	}
	
	// rename nick on whois dialogs
	for (WhoisDialog* d in whoisDialogs) {
		if ([d.nick isEqualToString:nick]) {
			d.nick = toNick;
		}
	}
	
	// rename nick in dcc
	[world.dcc nickChanged:nick toNick:toNick client:self];
	
	NSString* text = [NSString stringWithFormat:@"%@ is now known as %@", nick, toNick];
	[self printConsole:nil type:LINE_TYPE_NICK text:text];
}

- (void)receiveMode:(IRCMessage*)m
{
	NSString* nick = m.sender.nick;
	NSString* target = [m paramAt:0];
	NSString* modeStr = [m sequence:1];
	
	if ([target isChannelName]) {
		// channel
		IRCChannel* c = [self findChannel:target];
		if (c) {
			BOOL prevA = c.mode.a;
			NSArray* info = [c.mode update:modeStr];
			
			if (c.mode.a != prevA) {
				if (c.mode.a) {
					IRCUser* me = [c findMember:myNick];
					[[me retain] autorelease];
					[c addMember:me];
				}
				else {
					c.isWhoInit = NO;
					[self send:WHO, c.name, nil];
				}
			}
			
			for (IRCModeInfo* h in info) {
				if (!h.op) continue;
				
				unsigned char mode = h.mode;
				BOOL plus = h.plus;
				NSString* t = h.param;
				
				BOOL myself = NO;
				
				if ((mode == 'q' || mode == 'a' || mode == 'o') && [myNick isEqualNoCase:t]) {
					// mode change for myself
					IRCUser* m = [c findMember:myNick];
					if (m) {
						myself = YES;
						BOOL prev = m.isOp;
						[c changeMember:myNick mode:mode value:plus];
						c.isOp = m.isOp;
						if (!prev && c.isOp && c.isWhoInit) {
							// @@@ check all auto op
						}
					}
				}
				
				if (!myself) {
					[c changeMember:t mode:mode value:plus];
				}
			}
			
			[self updateChannelTitle:c];
		}
		
		NSString* text = [NSString stringWithFormat:@"%@ has changed mode: %@", nick, modeStr];
		[self printBoth:(c ?: (id)target) type:LINE_TYPE_MODE text:text];
	}
	else {
		// user mode
		[myMode update:modeStr];
		
		NSString* text = [NSString stringWithFormat:@"%@ has changed mode: %@", nick, modeStr];
		[self printBoth:nil type:LINE_TYPE_MODE text:text];
		[self updateClientTitle];
	}
}

- (void)receiveTopic:(IRCMessage*)m
{
	NSString* nick = m.sender.nick;
	NSString* chname = [m paramAt:0];
	NSString* topic = [m paramAt:1];
	
	IRCChannel* c = [self findChannel:chname];
	if (c) {
		c.topic = topic;
		[self updateChannelTitle:c];
	}
	
	NSString* text = [NSString stringWithFormat:@"%@ has set topic: %@", nick, topic];
	[self printBoth:(c ?: (id)chname) type:LINE_TYPE_TOPIC text:text];
}

- (void)receiveInvite:(IRCMessage*)m
{
	NSString* nick = m.sender.nick;
	NSString* chname = [m paramAt:1];
	
	if ([self checkIgnore:nil nick:nick channel:chname]) {
		return;
	}
	
	NSString* text = [NSString stringWithFormat:@"%@ has invited you to %@", nick, chname];
	[self printBoth:self type:LINE_TYPE_INVITE text:text];
	
	if ([Preferences autoJoinOnInvited]) {
		IRCChannel* c = [self findChannel:chname];
		if (!c) {
			IRCChannelConfig* seed = [[IRCChannelConfig new] autorelease];
			seed.name = chname;
			c = [world createChannel:seed client:self reload:YES adjust:YES];
			[world save];
			[self joinChannel:c];
		}
	}

	[self notifyEvent:GROWL_INVITED target:nil nick:nick text:chname];
	[SoundPlayer play:[Preferences soundForEvent:GROWL_INVITED]];
}

- (void)receiveError:(IRCMessage*)m
{
	[self printError:m.sequence];
}

- (void)receivePing:(IRCMessage*)m
{
	[self send:PONG, [m sequence:0], nil];
	
	[self stopPongTimer];
	[self startPongTimer];
}

- (void)receiveInit:(IRCMessage*)m
{
	if (isLoggedIn) return;
	
	[self startPongTimer];
	[self stopRetryTimer];
	[self stopAutoJoinTimer];
	
	[world expandClient:self];
	
	isLoggedIn = YES;
	conn.loggedIn = YES;
	tryingNickNumber = -1;
	
	registeringToNickServ = NO;
	inWhois = NO;
	inList = NO;
	
	[serverHostname release];
	serverHostname = [m.sender.raw retain];
	[myNick release];
	myNick = [[m paramAt:0] retain];
	
	[self printSystem:self text:@"Logged in"];
	
	[self notifyEvent:GROWL_LOGIN];
	[SoundPlayer play:[Preferences soundForEvent:GROWL_LOGIN]];
	
	if (config.nickPassword.length) {
		registeringToNickServ = YES;
		[self startAutoJoinTimer];
		[self send:PRIVMSG, @"NickServ", [NSString stringWithFormat:@"IDENTIFY %@", config.nickPassword], nil];
	}
	
	for (NSString* s in config.loginCommands) {
		if ([s hasPrefix:@"/"]) {
			s = [s substringFromIndex:1];
		}
		[self sendCommand:s completeTarget:NO target:nil];
	}
	
	for (IRCChannel* c in channels) {
		if (c.isTalk) {
			[c activate];
			
			IRCUser* m;
			m = [[IRCUser new] autorelease];
			m.nick = myNick;
			[c addMember:m];
			
			m = [[IRCUser new] autorelease];
			m.nick = c.name;
			[c addMember:m];
		}
	}
	
	[self updateClientTitle];
	[self reloadTree];
	
	if (!registeringToNickServ) {
		[self performAutoJoin];
	}
}

- (void)receiveNumericReply:(IRCMessage*)m
{
	int n = m.numericReply;
	if (400 <= n && n < 600 && n != 403 && n != 422) {
		[self receiveErrorNumericReply:m];
		return;
	}

	switch (n) {
		case 2 ... 4:
		case 10:
		case 20:
		case 42:
		case 250 ... 255:
		case 265 ... 266:
		case 372:
		case 375:
			[self printReply:m];
			break;
		case 1:		// RPL_WELCOME
		case 376:	// RPL_ENDOFMOTD
		case 422:	// ERR_NOMOTD
			[self receiveInit:m];
			[self printReply:m];
			break;
		case 5:		// RPL_ISUPPORT
			[isupport update:[m sequence:1]];
			[self printReply:m];
			break;
		case 221:	// RPL_UMODEIS
		{
			NSString* modeStr = [m paramAt:1];
			
			modeStr = [modeStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
			if ([modeStr isEqualToString:@"+"]) return;
			
			[myMode clear];
			[myMode update:modeStr];
			[self updateClientTitle];
			
			NSString* text = [NSString stringWithFormat:@"Mode: %@", modeStr];
			[self printBoth:nil type:LINE_TYPE_REPLY text:text];
			break;
		}
		case 290:	// RPL_CAPAB on freenode
		{
			NSString* kind = [m paramAt:1];
			kind = [kind lowercaseString];
			
			if ([kind isEqualToString:@"identify-msg"]) {
				identifyMsg = YES;
			}
			else if ([kind isEqualToString:@"identify-ctcp"]) {
				identifyCTCP = YES;
			}
			
			[self printReply:m];
			break;
		}
		case 301:	// RPL_AWAY
		{
			NSString* nick = [m paramAt:1];
			NSString* comment = [m paramAt:2];
			
			if (inWhois) {
				WhoisDialog* d = [self findWhoisDialog:nick];
				if (d) {
					[d setAwayMessage:comment];
					return;
				}
			}
			
			IRCChannel* c = [self findChannel:nick];
			NSString* text = [NSString stringWithFormat:@"%@ is away: %@", nick, comment];
			[self printBoth:(c ?: (id)nick) type:LINE_TYPE_REPLY text:text];
			break;
		}
		case 311:	// RPL_WHOISUSER
		{
			NSString* nick = [m paramAt:1];
			NSString* username = [m paramAt:2];
			NSString* address = [m paramAt:3];
			NSString* realname = [m paramAt:5];
			
			inWhois = YES;
			
			WhoisDialog* d = [self createWhoisDialogWithNick:nick username:username address:address realname:realname];
			if (!d) {
				NSString* text = [NSString stringWithFormat:@"%@ is %@ (%@@%@)", nick, realname, username, address];
				[self printBoth:nil type:LINE_TYPE_REPLY text:text];
			}
			break;
		}
		case 312:	// RPL_WHOISSERVER
		{
			NSString* nick = [m paramAt:1];
			NSString* server = [m paramAt:2];
			NSString* serverInfo = [m paramAt:3];
			
			if (inWhois) {
				WhoisDialog* d = [self findWhoisDialog:nick];
				if (d) {
					[d setServer:server serverInfo:serverInfo];
					return;
				}
			}
			
			NSString* text = [NSString stringWithFormat:@"%@ is on %@ (%@)", nick, server, serverInfo];
			[self printBoth:nil type:LINE_TYPE_REPLY text:text];
			break;
		}
		case 313:	// RPL_WHOISOPERATOR
		{
			NSString* nick = [m paramAt:1];
			
			if (inWhois) {
				WhoisDialog* d = [self findWhoisDialog:nick];
				if (d) {
					[d setIsOperator:YES];
					return;
				}
			}
			
			NSString* text = [NSString stringWithFormat:@"%@ is an IRC operator", nick];
			[self printBoth:nil type:LINE_TYPE_REPLY text:text];
			break;
		}
		case 317:	// RPL_WHOISIDLE
		{
			NSString* nick = [m paramAt:1];
			NSString* idleStr = [m paramAt:2];
			NSString* signOnStr = [m paramAt:3];
			
			NSString* idle = @"";
			NSString* signOn = @"";
			
			long long sec = [idleStr longLongValue];
			if (sec > 0) {
				long long min = sec / 60;
				sec %= 60;
				long long hour = min / 60;
				min %= 60;
				idle = [NSString stringWithFormat:@"%qi:%02qi:%02qi", hour, min, sec];
			}
			
			long long signOnTime = [signOnStr longLongValue];
			if (signOnTime > 0) {
				NSDate* date = [NSDate dateWithTimeIntervalSince1970:signOnTime];
				signOn = [dateTimeFormatter stringFromDate:date];
			}
			
			if (inWhois) {
				WhoisDialog* d = [self findWhoisDialog:nick];
				if (d) {
					[d setIdle:idle signOn:signOn];
					return;
				}
			}
			
			NSString* text;
			text = [NSString stringWithFormat:@"%@ is %@ idle", nick, idle];
			[self printBoth:nil type:LINE_TYPE_REPLY text:text];
			text = [NSString stringWithFormat:@"%@ logged in at %@", nick, signOn];
			[self printBoth:nil type:LINE_TYPE_REPLY text:text];
			break;
		}
		case 319:	// RPL_WHOISCHANNELS
		{
			NSString* nick = [m paramAt:1];
			NSString* trail = [m paramAt:2];
			
			trail = [trail stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
			NSArray* channelNames = [trail componentsSeparatedByString:@" "];
			
			if (inWhois) {
				WhoisDialog* d = [self findWhoisDialog:nick];
				if (d) {
					[d setChannels:channelNames];
					return;
				}
			}
			
			NSString* text = [NSString stringWithFormat:@"%@ is in %@", nick, trail];
			[self printBoth:nil type:LINE_TYPE_REPLY text:text];
			break;
		}
		case 318:	// RPL_ENDOFWHOIS
			inWhois = NO;
			break;
		case 324:	// RPL_CHANNELMODEIS
		{
			NSString* chname = [m paramAt:1];
			NSString* modeStr = [m sequence:2];
			
			modeStr = [modeStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
			if ([modeStr isEqualToString:@"+"]) return;
			
			IRCChannel* c = [self findChannel:chname];
			if (c && c.isActive) {
				BOOL prevA = c.mode.a;
				[c.mode clear];
				[c.mode update:modeStr];
				
				if (c.mode.a != prevA) {
					if (c.mode.a) {
						IRCUser* me = [c findMember:myNick];
						[[me retain] autorelease];
						[c clearMembers];
						[c addMember:me];
					}
					else {
						c.isWhoInit = NO;
						[self send:WHO, c.name, nil];
					}
				}
				
				c.isModeInit = YES;
				[self updateChannelTitle:c];
			}
			
			NSString* text = [NSString stringWithFormat:@"Mode: %@", modeStr];
			[self printBoth:(c ?: (id)chname) type:LINE_TYPE_REPLY text:text];
			break;
		}
		case 329:	// hemp ? channel creation time
		{
			NSString* chname = [m paramAt:1];
			NSString* timeStr = [m paramAt:2];
			long long timeNum = [timeStr longLongValue];
			
			IRCChannel* c = [self findChannel:chname];
			NSString* text = [NSString stringWithFormat:@"Created at: %@", [dateTimeFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:timeNum]]];
			[self printBoth:(c ?: (id)chname) type:LINE_TYPE_REPLY text:text];
			break;
		}
		case 331:	// RPL_NOTOPIC
		{
			NSString* chname = [m paramAt:1];
			
			IRCChannel* c = [self findChannel:chname];
			if (c && c.isActive) {
				c.topic = @"";
				[self updateChannelTitle:c];
			}
			
			NSString* text = @"Topic:";
			[self printBoth:(c ?: (id)chname) type:LINE_TYPE_REPLY text:text];
			break;
		}
		case 332:	// RPL_TOPIC
		{
			NSString* chname = [m paramAt:1];
			NSString* topic = [m paramAt:2];
			
			IRCChannel* c = [self findChannel:chname];
			if (c && c.isActive) {
				c.topic = topic;
				[self updateChannelTitle:c];
			}
			
			NSString* text = [NSString stringWithFormat:@"Topic: %@", topic];
			[self printBoth:(c ?: (id)chname) type:LINE_TYPE_REPLY text:text];
			break;
		}
		case 333:	// RPL_TOPIC_WHO_TIME
		{
			NSString* chname = [m paramAt:1];
			NSString* setter = [m paramAt:2];
			NSString* timeStr = [m paramAt:3];
			long long timeNum = [timeStr longLongValue];
			
			static NSCharacterSet* set = nil;
			if (!set) {
				set = [[NSCharacterSet characterSetWithCharactersInString:@"!@"] retain];
			}
			NSRange r = [setter rangeOfCharacterFromSet:set];
			if (r.location != NSNotFound) {
				setter = [setter substringToIndex:r.location];
			}
			
			IRCChannel* c = [self findChannel:chname];
			NSString* text = [NSString stringWithFormat:@"%@ set the topic at: %@", setter, [dateTimeFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:timeNum]]];
			[self printBoth:(c ?: (id)chname) type:LINE_TYPE_REPLY text:text];
			break;
		}
		case 341:	// RPL_INVITING
		{
			NSString* nick = [m paramAt:1];
			NSString* chname = [m paramAt:2];
			
			NSString* text = [NSString stringWithFormat:@"Inviting %@ to %@", nick, chname];
			[self printBoth:nil type:LINE_TYPE_REPLY text:text];
			break;
		}
		case 353:	// RPL_NAMREPLY
		{
			NSString* chname = [m paramAt:2];
			NSString* trail = [m paramAt:3];
			
			IRCChannel* c = [self findChannel:chname];
			if (c && c.isActive && !c.isNamesInit) {
				NSArray* ary = [trail componentsSeparatedByString:@" "];
				for (NSString* nick in ary) {
					if (!nick.length) continue;
					UniChar u = [nick characterAtIndex:0];
					char op = ' ';
					if (u == '@' || u == '~' || u == '&' || u == '%' || u == '+') {
						op = u;
						nick = [nick substringFromIndex:1];
					}
					
					IRCUser* m = [[IRCUser new] autorelease];
					m.nick = nick;
					m.q = op == '~';
					m.a = op == '&';
					m.o = op == '@' || m.q;
					m.h = op == '%';
					m.v = op == '+';
					m.isMyself = [nick isEqualNoCase:myNick];
					[c addMember:m reload:NO];
					if ([myNick isEqualNoCase:nick]) {
						c.isOp = (m.q || m.a | m.o);
					}
				}
				[c reloadMemberList];
				[self updateChannelTitle:c];
			}
			else {
				[self printBoth:c ?: (id)chname type:LINE_TYPE_REPLY text:[NSString stringWithFormat:@"Names: %@", trail]];
			}
			break;
		}
		case 366:	// RPL_ENDOFNAMES
		{
			NSString* chname = [m paramAt:1];
			
			IRCChannel* c = [self findChannel:chname];
			if (c && c.isActive && !c.isNamesInit) {
				c.isNamesInit = YES;
				
				if ([c numberOfMembers] <= 1 && c.isOp) {
					// set mode if creator
					NSString* m = c.config.mode;
					if (m.length) {
						NSString* line = [NSString stringWithFormat:@"%@ %@ %@", MODE, chname, m];
						[self sendLine:line];
					}
					c.isModeInit = YES;
				}
				else {
					// query mode
					[self send:MODE, chname, nil];
				}
				
				if ([c numberOfMembers] <= 1 && [chname isModeChannelName]) {
					NSString* topic = c.storedTopic;
					if (!topic.length) {
						topic = c.config.topic;
					}
					if (topic.length) {
						[self send:TOPIC, chname, topic, nil];
					}
				}
				
				if ([c numberOfMembers] > 1) {
					// @@@add to who queue
				}
				else {
					c.isWhoInit = YES;
				}
				
				[self updateChannelTitle:c];
			}
			break;
		}
		//case 352:	// RPL_WHOREPLY
		//case 315:	// RPL_ENDOFWHO
		case 321:	// RPL_LISTSTART obsolete
			break;
		case 322:	// RPL_LIST
		{
			NSString* chname = [m paramAt:1];
			NSString* countStr = [m paramAt:2];
			NSString* topic = [m sequence:3];
			
			if (!inList) {
				inList = YES;
				if (channelListDialog) {
					[channelListDialog clear];
				}
				else {
					[self createChannelListDialog];
				}
			}
			
			if (channelListDialog) {
				[channelListDialog addChannel:chname count:[countStr intValue] topic:topic];
			}
			else {
				NSString* text = [NSString stringWithFormat:@"%@ (%@) %@", chname, countStr, topic];
				[self printBoth:nil type:LINE_TYPE_REPLY text:text];
			}
			break;
		}
		case 323:	// RPL_LISTEND
			inList = NO;
			break;
		default:
			[self printUnknownReply:m];
			break;
	}
}

- (void)receiveErrorNumericReply:(IRCMessage*)m
{
	int n = m.numericReply;
	
	switch (n) {
		case 401:	// ERR_NOSUCHNICK
		{
			NSString* nick = [m paramAt:1];
			
			if (registeringToNickServ && [nick isEqualNoCase:@"NickServ"]) {
				[self performAutoJoin];
			}
			
			IRCChannel* c = [self findChannel:nick];
			if (c && c.isActive) {
				[self printErrorReply:m channel:c];
				return;
			}
			break;
		}
		case 433:	// ERR_NICKNAMEINUSE
			[self receiveNickCollisionError:m];
			break;
	}
	
	[self printErrorReply:m];
}

- (void)receiveNickCollisionError:(IRCMessage*)m
{
	if (config.altNicks.count && !isLoggedIn) {
		// only works when not logged in
		++tryingNickNumber;
		NSArray* altNicks = config.altNicks;
		
		if (tryingNickNumber < altNicks.count) {
			NSString* nick = [altNicks objectAtIndex:tryingNickNumber];
			[self send:NICK, nick, nil];
		}
		else {
			[self tryAnotherNick];
		}
	}
	else {
		[self tryAnotherNick];
	}
}

- (void)tryAnotherNick
{
	if (sentNick.length >= isupport.nickLen) {
		NSString* nick = [sentNick substringToIndex:isupport.nickLen];
		BOOL found = NO;
		
		for (int i=nick.length-1; i>=0; --i) {
			UniChar c = [nick characterAtIndex:i];
			if (c != '_') {
				found = YES;
				NSString* head = [nick substringToIndex:i];
				NSMutableString* s = [[head mutableCopy] autorelease];
				for (int i=isupport.nickLen - s.length; i>0; --i) {
					[s appendString:@"_"];
				}
				[sentNick release];
				sentNick = [s retain];
				break;
			}
		}
		
		if (!found) {
			[sentNick release];
			sentNick = @"0";
		}
	}
	else {
		[sentNick autorelease];
		sentNick = [[sentNick stringByAppendingString:@"_"] retain];
	}
	
	[self send:NICK, sentNick, nil];
}

#pragma mark -
#pragma mark IRCConnection Delegate

- (void)changeStateOff
{
	BOOL prevConnected = isConnected;
	
	[conn autorelease];
	conn = nil;
	
	[self clearCommandQueue];
	[self stopPongTimer];
	[self stopQuitTimer];
	[self stopRetryTimer];
	
	if (reconnectEnabled) {
		[self startReconnectTimer];
	}
	
	isConnecting = isConnected = isLoggedIn = isQuitting = NO;
	[myNick release];
	myNick = @"";
	[sentNick release];
	sentNick = @"";
	
	tryingNickNumber = -1;
	[joinMyAddress release];
	joinMyAddress = nil;
	
	inWhois = NO;
	inList = NO;
	identifyMsg = NO;
	identifyCTCP = NO;
	
	for (IRCChannel* c in channels) {
		if (c.isActive) {
			[c deactivate];
			[self printSystem:c text:@"Disconnected"];
		}
	}
	
	[self printSystemBoth:nil text:@"Disconnected"];
	
	[self updateClientTitle];
	[self reloadTree];
	
	if (prevConnected) {
		[self notifyEvent:GROWL_DISCONNECT];
		[SoundPlayer play:[Preferences soundForEvent:GROWL_DISCONNECT]];
	}
}

- (void)ircConnectionDidConnect:(IRCConnection*)sender
{
	[self startRetryTimer];
	
	[self printSystemBoth:nil text:@"Connected"];
	
	isConnecting = isLoggedIn = NO;
	isConnected = reconnectEnabled = YES;
	encoding = config.encoding;
	
	if (!inputNick.length) {
		[inputNick autorelease];
		inputNick = [config.nick retain];
	}
	[sentNick autorelease];
	[myNick autorelease];
	sentNick = [inputNick retain];
	myNick = [inputNick retain];
	
	[isupport reset];
	[myMode clear];
	
	int modeParam = config.invisibleMode ? 8 : 0;
	NSString* user = config.username;
	NSString* realName = config.realName;
	
	if (!user.length) user = config.nick;
	if (!realName.length) realName = config.nick;
	
	if (config.password.length) [self send:PASS, config.password, nil];
	[self send:NICK, sentNick, nil];
	[self send:USER, user, [NSString stringWithFormat:@"%d", modeParam], @"*", realName, nil];
	
	[self updateClientTitle];
}

- (void)ircConnectionDidDisconnect:(IRCConnection*)sender
{
	[self changeStateOff];
}

- (void)ircConnectionDidError:(NSString*)error
{
	[self printError:error];
}

- (void)ircConnectionDidReceive:(NSData*)data
{
	NSStringEncoding enc = encoding;
	if (encoding == NSUTF8StringEncoding && config.fallbackEncoding != NSUTF8StringEncoding && ![data isValidUTF8]) {
		enc = config.fallbackEncoding;
	}
	
	if (encoding == NSISO2022JPStringEncoding) {
		data = [data convertKanaFromNativeToISO2022];
	}
	
	NSString* s = [[[NSString alloc] initWithData:data encoding:enc] autorelease];
	if (!s) {
		if (encoding == NSISO2022JPStringEncoding) {
			// avoid incomplete sequence
			NSMutableData* d = [[data mutableCopy] autorelease];
			while (d.length > 1) {
				[d setLength:d.length - 1];
				s = [[[NSString alloc] initWithData:d encoding:enc] autorelease];
				if (s) break;
			}
		}
		
		if (!s) {
			s = [[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] autorelease];
			if (!s) return;
		}
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

#pragma mark -
#pragma mark Init

+ (void)load
{
	if (self != [IRCClient class]) return;
	
	NSAutoreleasePool* pool = [NSAutoreleasePool new];
	
	dateTimeFormatter = [NSDateFormatter new];
	[dateTimeFormatter setDateStyle:NSDateFormatterMediumStyle];
	[dateTimeFormatter setTimeStyle:NSDateFormatterShortStyle];
	
	[pool drain];
}

@end
