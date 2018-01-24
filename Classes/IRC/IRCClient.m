// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "IRCClient.h"
#import "IRC.h"
#import "IRCWorld.h"
#import "IRCMessage.h"
#import "Preferences.h"
#import "WhoisDialog.h"
#import "SoundPlayer.h"
#import "TimerCommand.h"
#import "NSStringHelper.h"
#import "NSDataHelper.h"
#import "NSData+Kana.h"
#import "GTMBase64.h"


#define MAX_JOIN_CHANNELS   10
#define MAX_BODY_LEN        480
#define TIME_BUFFER_SIZE    256

#define QUIT_INTERVAL       5
#define RECONNECT_INTERVAL  20
#define RETRY_INTERVAL      240
#define NICKSERV_INTERVAL   5

#define CTCP_MIN_INTERVAL   5

@interface IRCClient () <HostResolverDelegate>
@end

@implementation IRCClient
{
    IRCConnection* _conn;
    int _connectDelay;
    BOOL _reconnectEnabled;
    BOOL _retryEnabled;
    BOOL _isQuitting;
    NSStringEncoding _encoding;

    NSString* _inputNick;
    NSString* _sentNick;
    int _tryingNickNumber;

    NSString* _serverHostname;
    BOOL _isRegisteredWithSASL;
    BOOL _registeringToNickServ;
    BOOL _inWhois;
    BOOL _inList;
    BOOL _identifyMsg;
    BOOL _identifyCTCP;

    AddressDetectionType _addressDetectionMethod;
    HostResolver* _nameResolver;
    NSString* _joinMyAddress;
    CFAbsoluteTime _lastCTCPTime;
    int _pongInterval;
    CFAbsoluteTime _joinSentTime;
    NSString* _joiningChannelName;

    Timer* _pongTimer;
    Timer* _quitTimer;
    Timer* _reconnectTimer;
    Timer* _retryTimer;
    Timer* _autoJoinTimer;
    Timer* _commandQueueTimer;
    NSMutableArray* _commandQueue;

    NSMutableArray* _whoisDialogs;
    ListDialog* _channelListDialog;
}

- (id)init
{
    self = [super init];
    if (self) {
        _tryingNickNumber = -1;
        _channels = [NSMutableArray new];
        _isupport = [IRCISupportInfo new];
        _myMode = [IRCUserMode new];
        _whoisDialogs =
        [NSMutableArray new];

        _nameResolver = [HostResolver new];
        _nameResolver.delegate = self;

        _pongTimer = [Timer new];
        _pongTimer.delegate = self;
        _pongTimer.reqeat = YES;
        _pongTimer.selector = @selector(onPongTimer:);

        _quitTimer = [Timer new];
        _quitTimer.delegate = self;
        _quitTimer.reqeat = NO;
        _quitTimer.selector = @selector(onQuitTimer:);

        _reconnectTimer = [Timer new];
        _reconnectTimer.delegate = self;
        _reconnectTimer.reqeat = NO;
        _reconnectTimer.selector = @selector(onReconnectTimer:);

        _retryTimer = [Timer new];
        _retryTimer.delegate = self;
        _retryTimer.reqeat = NO;
        _retryTimer.selector = @selector(onRetryTimer:);

        _autoJoinTimer = [Timer new];
        _autoJoinTimer.delegate = self;
        _autoJoinTimer.reqeat = NO;
        _autoJoinTimer.selector = @selector(onAutoJoinTimer:);

        _commandQueueTimer = [Timer new];
        _commandQueueTimer.delegate = self;
        _commandQueueTimer.reqeat = NO;
        _commandQueueTimer.selector = @selector(onCommandQueueTimer:);

        _commandQueue = [NSMutableArray new];

    }
    return self;
}

- (void)dealloc
{
    [_conn close];
    _nameResolver.delegate = nil;
    [_pongTimer stop];
    [_quitTimer stop];
    [_reconnectTimer stop];
    [_retryTimer stop];
    [_autoJoinTimer stop];
    [_commandQueueTimer stop];
}

#pragma mark - Init

- (void)setup:(IRCClientConfig*)seed
{
    _config = [seed mutableCopy];

    _addressDetectionMethod = [Preferences dccAddressDetectionMethod];
    if (_addressDetectionMethod == ADDRESS_DETECT_SPECIFY) {
        NSString* host = [Preferences dccMyaddress];
        if (host.length) {
            [_nameResolver resolve:host];
        }
    }
}

- (void)updateConfig:(IRCClientConfig*)seed
{
    _config = [seed mutableCopy];

    NSArray* chans = _config.channels;

    NSMutableArray* ary = [NSMutableArray array];

    for (IRCChannelConfig* i in chans) {
        IRCChannel* c = [self findChannel:i.name];
        if (c) {
            [c updateConfig:i];
            [ary addObject:c];
            [_channels removeObjectIdenticalTo:c];
        }
        else {
            c = [_world createChannel:i client:self reload:NO adjust:NO];
            [ary addObject:c];
        }
    }

    for (IRCChannel* c in _channels) {
        if (c.isChannel) {
            [self partChannel:c];
        }
        else {
            [ary addObject:c];
        }
    }

    [_channels removeAllObjects];
    [_channels addObjectsFromArray:ary];

    [_config.channels removeAllObjects];

    [_world reloadTree];
    [_world adjustSelection];
}

- (IRCClientConfig*)storedConfig
{
    IRCClientConfig* u = [_config mutableCopy];
    u.uid = self.uid;
    [u.channels removeAllObjects];

    for (IRCChannel* c in _channels) {
        if (c.isChannel) {
            [u.channels addObject:[c.config mutableCopy]];
        }
    }

    return u;
}

- (NSMutableDictionary*)dictionaryValue
{
    NSMutableDictionary* dic = [_config dictionaryValueSavingToKeychain:YES includingChildren:NO];

    NSMutableArray* ary = [NSMutableArray array];
    for (IRCChannel* c in _channels) {
        if (c.isChannel) {
            [ary addObject:[c dictionaryValue]];
        }
    }

    [dic setObject:ary forKey:@"channels"];
    return dic;
}

#pragma mark - Properties

- (NSString*)name
{
    return _config.name;
}

- (BOOL)isNewTalk
{
    return NO;
}

- (BOOL)isReconnecting
{
    return _reconnectTimer && _reconnectTimer.isActive;
}

#pragma mark - Utilities

- (void)autoConnect:(int)delay
{
    _connectDelay = delay;
    [self connect];
}

- (void)onTimer
{
}

- (void)terminate
{
    [self quit];
    [self closeDialogs];
    for (IRCChannel* c in _channels) {
        [c terminate];
    }
    [self disconnect];
}

- (void)closeDialogs
{
    for (WhoisDialog* d in _whoisDialogs) {
        [d close];
    }
    [_whoisDialogs removeAllObjects];

    [_channelListDialog close];
}

- (void)preferencesChanged
{
    self.log.maxLines = [Preferences maxLogLines];

    if (_addressDetectionMethod != [Preferences dccAddressDetectionMethod]) {
        _addressDetectionMethod = [Preferences dccAddressDetectionMethod];

        _myAddress = nil;

        if (_addressDetectionMethod == ADDRESS_DETECT_SPECIFY) {
            NSString* host = [Preferences dccMyaddress];
            if (host.length) {
                [_nameResolver resolve:host];
            }
        }
        else {
            if (_joinMyAddress.length) {
                [_nameResolver resolve:_joinMyAddress];
            }
        }
    }

    if (_isLoggedIn) {
        if (_pongInterval != [Preferences pongInterval]) {
            if (_serverHostname.length) {
                [self send:PONG, _serverHostname, nil];
            }
            [self stopPongTimer];
            [self startPongTimer];
        }
    }

    for (IRCChannel* c in _channels) {
        [c preferencesChanged];
    }
}

- (void)reloadTree
{
    [_world reloadTree];
}

- (BOOL)checkIgnore:(NSString*)text nick:(NSString*)nick channel:(NSString*)channel
{
    for (IgnoreItem* g in _config.ignores) {
        if ([g checkIgnore:text nick:nick channel:channel]) {
            return YES;
        }
    }

    return NO;
}

#pragma mark - ListDialog

- (void)createChannelListDialog
{
    if (!_channelListDialog) {
        _channelListDialog = [ListDialog new];
        _channelListDialog.delegate = self;
        [_channelListDialog start];
    }
    else {
        [_channelListDialog show];
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
    _channelListDialog = nil;
}

#pragma mark - Timers

- (void)startPongTimer
{
    if (!_isLoggedIn) return;
    if (_pongTimer.isActive) return;

    _pongInterval = [Preferences pongInterval];
    [_pongTimer start:_pongInterval];
}

- (void)stopPongTimer
{
    [_pongTimer stop];
}

- (void)onPongTimer:(id)sender
{
    if (_isLoggedIn) {
        if (_serverHostname.length) {
            [self send:PONG, _serverHostname, nil];
        }
    }
    else {
        [self stopPongTimer];
    }
}

- (void)startQuitTimer
{
    if (_quitTimer.isActive) return;

    [_quitTimer start:QUIT_INTERVAL];
}

- (void)stopQuitTimer
{
    [_quitTimer stop];
}

- (void)onQuitTimer:(id)sender
{
    [self disconnect];
}

- (void)startReconnectTimer
{
    if (_reconnectTimer.isActive) return;

    [_reconnectTimer start:RECONNECT_INTERVAL];
}

- (void)stopReconnectTimer
{
    [_reconnectTimer stop];
}

- (void)onReconnectTimer:(id)sender
{
    [self connect:CONNECT_RECONNECT];
}

- (void)startRetryTimer
{
    if (_retryTimer.isActive) return;

    [_retryTimer start:RETRY_INTERVAL];
}

- (void)stopRetryTimer
{
    [_retryTimer stop];
}

- (void)onRetryTimer:(id)sender
{
    [self disconnect];
    [self connect:CONNECT_RETRY];
}

- (void)startAutoJoinTimer
{
    [_autoJoinTimer stop];
    [_autoJoinTimer start:NICKSERV_INTERVAL];
}

- (void)stopAutoJoinTimer
{
    [_autoJoinTimer stop];
}

- (void)onAutoJoinTimer:(id)sender
{
    [self performAutoJoin];
}

#pragma mark - Commands

- (void)connect
{
    [self connect:CONNECT_NORMAL];
}

- (void)connect:(ConnectMode)mode
{
    [self stopReconnectTimer];

    if (_conn) {
        [_conn close];
        _conn = nil;
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

    _isConnecting = YES;
    _reconnectEnabled = YES;
    _retryEnabled = YES;

    NSString* host = _config.host;
    if (host) {
        int n = [host findCharacter:' '];
        if (n >= 0) {
            host = [host substringToIndex:n];
        }
    }

    _conn = [IRCConnection new];
    _conn.delegate = self;
    _conn.host = host;
    _conn.port = _config.port;
    _conn.useSSL = _config.useSSL;
    _conn.encoding = _config.encoding;

    switch (_config.proxyType) {
        case PROXY_SOCKS_SYSTEM:
            _conn.useSystemSocks = YES;
            // fall through
        case PROXY_SOCKS4:
        case PROXY_SOCKS5:
            _conn.useSocks = YES;
            _conn.socksVersion = _config.proxyType;
            _conn.proxyHost = _config.proxyHost;
            _conn.proxyPort = _config.proxyPort;
            _conn.proxyUser = _config.proxyUser;
            _conn.proxyPassword = _config.proxyPassword;
            break;
        default:
            break;
    }

    [_conn open];
}

- (void)disconnect
{
    if (_conn) {
        [_conn close];
        _conn = nil;
    }

    [self changeStateOff];
}

- (void)quit
{
    [self quit:nil];

    // Reset nick when disconnected from menu
    _inputNick = nil;
}

- (void)quit:(NSString*)comment
{
    if (!_isLoggedIn) {
        [self disconnect];
        return;
    }

    _isQuitting = YES;
    _reconnectEnabled = NO;
    [_conn clearSendQueue];
    [self send:QUIT, comment ?: _config.leavingComment, nil];

    [self startQuitTimer];
}

- (void)cancelReconnect
{
    [self stopReconnectTimer];
}

- (void)changeNick:(NSString*)newNick
{
    if (!_isConnected) return;

    _inputNick = newNick;
    _sentNick = newNick;

    [self send:NICK, newNick, nil];
}

- (void)joinChannel:(IRCChannel*)channel
{
    if (!_isLoggedIn) return;
    if (channel.isActive) return;

    NSString* password = channel.config.password;
    if (!password.length) password = nil;

    [self send:JOIN, channel.name, password, nil];
}

- (void)joinChannel:(IRCChannel*)channel password:(NSString*)password
{
    if (!_isLoggedIn) return;

    if (!password.length) password = channel.config.password;
    if (!password.length) password = nil;

    [self send:JOIN, channel.name, password, nil];
}

- (void)partChannel:(IRCChannel*)channel
{
    if (!_isLoggedIn) return;
    if (!channel.isActive) return;

    NSString* comment = _config.leavingComment;
    if (!comment.length) comment = nil;

    [self send:PART, channel.name, comment, nil];
}

- (void)sendWhois:(NSString*)nick
{
    if (!_isLoggedIn) return;

    [self send:WHOIS, nick, nick, nil];
}

- (void)changeOp:(IRCChannel*)channel users:(NSArray*)inputUsers mode:(char)mode value:(BOOL)value
{
    if (!_isLoggedIn || !channel || !channel.isActive || !channel.isChannel || !channel.isOp) return;

    NSMutableArray* users = [NSMutableArray array];

    for (IRCUser* user in inputUsers) {
        IRCUser* m = [channel findMember:user.nick];
        if (m) {
            if (value != [m hasMode:mode]) {
                [users addObject:m];
            }
        }
    }

    int max = _isupport.modesCount;
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

    static NSRegularExpression* addressRegexp = nil;
    if (!addressRegexp) {
        NSString* pattern = @"([0-9]{1,3})\\.([0-9]{1,3})\\.([0-9]{1,3})\\.([0-9]{1,3})";
        addressRegexp = [[NSRegularExpression alloc] initWithPattern:pattern options:0 error:NULL];
    }

    NSString* address = nil;

    if (_myAddress) {
        NSTextCheckingResult* result = [addressRegexp firstMatchInString:_myAddress options:0 range:NSMakeRange(0, _myAddress.length)];
        if (!result || result.numberOfRanges < 5) {
            address = _myAddress;
        }
        else {
            int w = [[_myAddress substringWithRange:[result rangeAtIndex:1]] intValue];
            int x = [[_myAddress substringWithRange:[result rangeAtIndex:2]] intValue];
            int y = [[_myAddress substringWithRange:[result rangeAtIndex:3]] intValue];
            int z = [[_myAddress substringWithRange:[result rangeAtIndex:4]] intValue];

            unsigned long long a = 0;
            a |= w; a <<= 8;
            a |= x; a <<= 8;
            a |= y; a <<= 8;
            a |= z;

            address = [NSString stringWithFormat:@"%qu", a];
        }
    }

    NSString* trail = [NSString stringWithFormat:@"%@ %@ %d %qi", escapedFileName, address, port, size];
    [self sendCTCPQuery:nick command:@"DCC SEND" text:trail];

    NSString* text = [NSString stringWithFormat:@"Trying file transfer to %@, %@ (%qi bytes) %@:%d", nick, fileName, size, _myAddress, port];
    [self printBoth:nil type:LINE_TYPE_DCC_SEND_SEND text:text];
}

- (void)quickJoin:(NSArray*)chans
{
    NSMutableString* target = [NSMutableString string];
    NSMutableString* pass = [NSMutableString string];

    for (IRCChannel* c in chans) {
        NSMutableString* prevTarget = [target mutableCopy];
        NSMutableString* prevPass = [pass mutableCopy];

        if (target.length) [target appendString:@","];
        [target appendString:c.name];
        if (c.password.length) {
            if (pass.length) [pass appendString:@","];
            [pass appendString:c.password];
        }

        NSData* targetData = [target dataUsingEncoding:_conn.encoding];
        NSData* passData = [pass dataUsingEncoding:_conn.encoding];

        if (targetData.length + passData.length > MAX_BODY_LEN) {
            if (prevTarget.length) {
                if (!prevPass.length) {
                    [self send:JOIN, prevTarget, nil];
                }
                else {
                    [self send:JOIN, prevTarget, prevPass, nil];
                }
                [target setString:c.name];
                [pass setString:c.password];
            }
            else {
                if (!c.password.length) {
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

    if (target.length) {
        if (!pass.length) {
            [self send:JOIN, target, nil];
        }
        else {
            [self send:JOIN, target, pass, nil];
        }
    }
}

- (void)performAutoJoin
{
    _registeringToNickServ = NO;
    [self stopAutoJoinTimer];

    NSMutableArray* ary = [NSMutableArray array];
    for (IRCChannel* c in _channels) {
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
        BOOL hasPass = c.password.length > 0;

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
    if (_myMode.r) return;
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

#pragma mark - Sending Text

- (BOOL)inputText:(NSString*)str command:(NSString*)command
{
    if (!_isConnected) return NO;

    id sel = _world.selected;
    if (!sel) return NO;

    NSArray* lines = [str splitIntoLines];
    for (NSString* line in lines) {
        NSString* s = line;
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
        max -= [_conn convertToCommonEncoding:chname].length;
    }

    if (_myNick.length) {
        max -= _myNick.length;
    }
    else {
        max -= _isupport.nickLen;
    }

    max -= _config.username.length;

    if (_joinMyAddress) {
        max -= _joinMyAddress.length;
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
        s = [s copy];
    }

    while (1) {
        int len = [_conn convertToCommonEncoding:s].length;
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

        NSMutableString* s = [line mutableCopy];

        while (s.length > 0) {
            NSString* t = [self truncateText:s command:command channelName:channel.name];
            if (!t.length) break;

            [self printBoth:channel type:type nick:_myNick text:t identified:YES];

            NSString* cmd = command;
            if (type == LINE_TYPE_ACTION) {
                cmd = PRIVMSG;
                t = [NSString stringWithFormat:@"\x01%@ %@\x01", ACTION, t];
            }
            [self send:cmd, channel.name, t, nil];
        }

        if ([command isEqualToString:PRIVMSG]) {
            NSString* recipientNick = nil;

            static NSRegularExpression* headPattern = nil;
            static NSRegularExpression* tailPattern = nil;
            static NSRegularExpression* twitterPattern = nil;

            if (!headPattern) {
                headPattern = [[NSRegularExpression alloc] initWithPattern:@"^([^\\s:]+):\\s?" options:0 error:NULL];
            }
            if (!tailPattern) {
                tailPattern = [[NSRegularExpression alloc] initWithPattern:@"[>＞]\\s?([^\\s]+)$" options:0 error:NULL];
            }
            if (!twitterPattern) {
                twitterPattern = [[NSRegularExpression alloc] initWithPattern:@"^@([0-9a-zA-Z_]+)\\s" options:0 error:NULL];
            }

            NSTextCheckingResult* result = [headPattern firstMatchInString:line options:0 range:NSMakeRange(0, line.length)];
            if (result && result.numberOfRanges > 1) {
                recipientNick = [line substringWithRange:[result rangeAtIndex:1]];
            }
            else {
                result = [tailPattern firstMatchInString:line options:0 range:NSMakeRange(0, line.length)];
                if (result) {
                    recipientNick = [line substringWithRange:[result rangeAtIndex:1]];
                }
                else {
                    result = [twitterPattern firstMatchInString:line options:0 range:NSMakeRange(0, line.length)];
                    if (result) {
                        recipientNick = [line substringWithRange:[result rangeAtIndex:1]];
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
    return [s stringByReplacingOccurrencesOfString:@"$nick" withString:_myNick];
}

- (void)sendJoinAndSelect:(NSString*)channelName
{
    _joiningChannelName = channelName;
    _joinSentTime = CFAbsoluteTimeGetCurrent();
    [self send:JOIN, _joiningChannelName, nil];
}

- (BOOL)sendCommand:(NSString*)s
{
    return [self sendCommand:s completeTarget:YES target:nil];
}

- (BOOL)sendCommand:(NSString*)str completeTarget:(BOOL)completeTarget target:(NSString*)targetChannelName
{
    if (!_isConnected || !str.length) return NO;

    str = [self expandVariables:str];

    NSMutableString* s = [str mutableCopy];

    NSString* cmd = [[s getToken] uppercaseString];
    if (!cmd.length) return NO;

    IRCClient* u = _world.selectedClient;
    IRCChannel* c = _world.selectedChannel;

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
                [_world destroyChannel:c];
            }
        }
        else {
            // open a new talk
            IRCChannel* c = [self findChannel:nick];
            if (!c) {
                c = [_world createTalk:nick client:self];
            }
            [_world select:c];
        }
        return YES;
    }
    else if ([cmd isEqualToString:CLOSE]) {
        NSString* nick = [s getToken];
        if (nick.length) {
            c = [self findChannel:nick];
        }
        if (c && c.isTalk) {
            [_world destroyChannel:c];
        }
        return YES;
    }
    else if ([cmd isEqualToString:TIMER]) {
        int interval = [[s getToken] intValue];
        if (interval > 0) {
            TimerCommand* cmd = [TimerCommand new];
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
    else if ([cmd isEqualToString:MSG] || [cmd isEqualToString:CMD_M]) {
        cmd = PRIVMSG;
    }
    else if ([cmd isEqualToString:LEAVE]) {
        cmd = PART;
    }
    else if ([cmd isEqualToString:CMD_J]) {
        cmd = JOIN;
    }
    else if ([cmd isEqualToString:CMD_T]) {
        cmd = TOPIC;
    }
    else if ([cmd isEqualToString:IGNORE] || [cmd isEqualToString:UNIGNORE]) {
        if (!s.length) {
            [_world.menuController showServerPropertyDialog:self ignore:YES];
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

        IgnoreItem* g = [IgnoreItem new];
        g.nick = nick;
        g.text = text;
        g.useRegexForNick = useRegexForNick;
        g.useRegexForText = useRegexForText;
        g.channels = chnames;

        if (g.isValid) {
            if ([cmd isEqualToString:IGNORE]) {
                BOOL found = NO;
                for (IgnoreItem* e in _config.ignores) {
                    if ([g isEqual:e]) {
                        found = YES;
                        break;
                    }
                }

                if (!found) {
                    [_config.ignores addObject:g];
                    [_world save];
                }
            }
            else {
                NSMutableArray* ignores = _config.ignores;
                for (int i=ignores.count-1; i>=0; --i) {
                    IgnoreItem* e = [ignores objectAtIndex:i];
                    if ([g isEqual:e]) {
                        [ignores removeObjectAtIndex:i];
                        [_world save];
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
            [_world destroyChannel:selChannel];
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
        [s insertString:_myNick atIndex:0];
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
        NSMutableString* t = [s mutableCopy];
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
            for (NSString* channelName in targets) {
                NSString* chname = channelName;
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
                    c = [_world createTalk:chname client:self];
                }

                [self printBoth:(c ?: (id)chname) type:type nick:_myNick text:t identified:YES];

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
    [_conn sendLine:str];

    LOG(@">>> %@", str);
}

- (void)send:(NSString*)str, ...
{
    NSMutableArray* ary = [NSMutableArray array];

    id obj;
    va_list args;
    va_start(args, str);
    while ((obj = va_arg(args, id))) {
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

#pragma mark - Find Channel

- (IRCChannel*)findChannel:(NSString*)name
{
    for (IRCChannel* c in _channels) {
        if ([c.name isEqualNoCase:name]) {
            return c;
        }
    }
    return nil;
}

- (int)indexOfTalkChannel
{
    int i = 0;
    for (IRCChannel* e in _channels) {
        if (e.isTalk) return i;
        ++i;
    }
    return -1;
}

#pragma mark - Command Queue

- (void)processCommandsInCommandQueue
{
    CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();

    while (_commandQueue.count) {
        TimerCommand* m = [_commandQueue objectAtIndex:0];
        if (m.time <= now) {
            NSString* target = nil;
            IRCChannel* c = [_world findChannelByClientId:self.uid channelId:m.cid];
            if (c) {
                target = c.name;
            }

            [self sendCommand:m.input completeTarget:YES target:target];

            [_commandQueue removeObjectAtIndex:0];
        }
        else {
            break;
        }
    }

    if (_commandQueue.count) {
        TimerCommand* m = [_commandQueue objectAtIndex:0];
        CFAbsoluteTime delta = m.time - CFAbsoluteTimeGetCurrent();
        [_commandQueueTimer start:delta];
    }
    else {
        [_commandQueueTimer stop];
    }
}

- (void)addCommandToCommandQueue:(TimerCommand*)m
{
    BOOL added = NO;
    int i = 0;
    for (TimerCommand* c in _commandQueue) {
        if (m.time < c.time) {
            added = YES;
            [_commandQueue insertObject:m atIndex:i];
            break;
        }
        ++i;
    }

    if (!added) {
        [_commandQueue addObject:m];
    }

    if (i == 0) {
        [self processCommandsInCommandQueue];
    }
}

- (void)clearCommandQueue
{
    [_commandQueueTimer stop];
    [_commandQueue removeAllObjects];
}

- (void)onCommandQueueTimer:(id)sender
{
    [self processCommandsInCommandQueue];
}

#pragma mark - Window Title

- (void)updateClientTitle
{
    [_world updateClientTitle:self];
}

- (void)updateChannelTitle:(IRCChannel*)c
{
    [_world updateChannelTitle:c];
}

#pragma mark - User Notification

- (void)notifyText:(UserNotificationType)type target:(id)target nick:(NSString*)nick text:(NSString*)text
{
    if ([Preferences stopNotificationsOnActive] && [NSApp isActive]) return;
    if (![Preferences userNotificationEnabledForEvent:type]) return;

    IRCChannel* channel = nil;
    NSString* chname = nil;
    if (target) {
        if ([target isKindOfClass:[IRCChannel class]]) {
            channel = (IRCChannel*)target;
            chname = channel.name;
            if (!channel.config.notify) {
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

    NSMutableDictionary* context = [NSMutableDictionary dictionary];
    [context setObject:@(self.uid) forKey:USER_NOTIFICATION_CLIENT_ID_KEY];
    if (channel) {
        [context setObject:@(channel.uid) forKey:USER_NOTIFICATION_CHANNEL_ID_KEY];
    }
    if (type == USER_NOTIFICATION_INVITED && text) {
        [context setObject:text forKey:USER_NOTIFICATION_INVITED_CHANNEL_NAME_KEY];
    }

    [_world sendUserNotification:type title:title desc:desc context:context];
}

- (void)notifyEvent:(UserNotificationType)type
{
    [self notifyEvent:type target:nil nick:@"" text:@""];
}

- (void)notifyEvent:(UserNotificationType)type target:(id)target nick:(NSString*)nick text:(NSString*)text
{
    if ([Preferences stopNotificationsOnActive] && [NSApp isActive]) return;
    if (![Preferences userNotificationEnabledForEvent:type]) return;

    IRCChannel* channel = nil;
    if (target) {
        if ([target isKindOfClass:[IRCChannel class]]) {
            channel = (IRCChannel*)target;
            if (!channel.config.notify) {
                return;
            }
        }
    }

    NSString* title = @"";
    NSString* desc = @"";

    switch (type) {
        case USER_NOTIFICATION_LOGIN:
            title = self.name;
            break;
        case USER_NOTIFICATION_DISCONNECT:
            title = self.name;
            break;
        case USER_NOTIFICATION_KICKED:
            title = channel.name;
            desc = [NSString stringWithFormat:@"%@ has kicked out you : %@", nick, text];
            break;
        case USER_NOTIFICATION_INVITED:
            title = self.name;
            desc = [NSString stringWithFormat:@"%@ has invited you to %@", nick, text];
            break;
        default:
            return;
    }

    NSMutableDictionary* context = [NSMutableDictionary dictionary];
    [context setObject:@(self.uid) forKey:USER_NOTIFICATION_CLIENT_ID_KEY];
    if (channel) {
        [context setObject:@(channel.uid) forKey:USER_NOTIFICATION_CHANNEL_ID_KEY];
    }
    if (type == USER_NOTIFICATION_INVITED && text) {
        [context setObject:text forKey:USER_NOTIFICATION_INVITED_CHANNEL_NAME_KEY];
    }

    [_world sendUserNotification:type title:title desc:desc context:context];
}

#pragma mark - Channel States

- (void)setKeywordState:(id)t
{
    if ([NSApp isActive] && _world.selected == t) return;
    if ([t isKeyword]) return;
    [t setIsKeyword:YES];
    [self reloadTree];
    if (![NSApp isActive]) [NSApp requestUserAttention:NSInformationalRequest];
    [_world updateIcon];
}

- (void)setNewTalkState:(id)t
{
    if ([NSApp isActive] && _world.selected == t) return;
    if ([t isNewTalk]) return;
    [t setIsNewTalk:YES];
    [self reloadTree];
    if (![NSApp isActive]) [NSApp requestUserAttention:NSInformationalRequest];
    [_world updateIcon];
}

- (void)setUnreadState:(id)t
{
    if ([NSApp isActive] && _world.selected == t) return;
    if ([t isUnread]) return;
    [t setIsUnread:YES];
    [self reloadTree];
    [_world updateIcon];
}

#pragma mark - Print

- (NSString*)formatTimestamp:(time_t)global
{
    NSString* format = @"%H:%M";
    if ([Preferences themeOverrideTimestampFormat]) {
        format = [Preferences themeTimestampFormat];
    }

    struct tm* local = localtime(&global);
    char buf[TIME_BUFFER_SIZE+1];
    strftime(buf, TIME_BUFFER_SIZE, [format UTF8String], local);
    buf[TIME_BUFFER_SIZE] = 0;
    NSString* result = [[NSString alloc] initWithBytes:buf length:strlen(buf) encoding:NSUTF8StringEncoding];
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

    return target != _world.selected || !target.log.viewingBottom;
}

- (BOOL)printBoth:(id)chan type:(LogLineType)type text:(NSString*)text
{
    time_t receivedAt;
    time(&receivedAt);
    return [self printBoth:chan type:type nick:nil text:text identified:NO timestamp:receivedAt];
}

- (BOOL)printBoth:(id)chan type:(LogLineType)type text:(NSString*)text timestamp:(time_t)receivedAt
{
    return [self printBoth:chan type:type nick:nil text:text identified:NO timestamp:receivedAt];
}

- (BOOL)printBoth:(id)chan type:(LogLineType)type nick:(NSString*)nick text:(NSString*)text identified:(BOOL)identified
{
    time_t receivedAt;
    time(&receivedAt);
    return [self printBoth:chan type:type nick:nick text:text identified:identified timestamp:receivedAt];
}

- (BOOL)printBoth:(id)chan type:(LogLineType)type nick:(NSString*)nick text:(NSString*)text identified:(BOOL)identified timestamp:(time_t)receivedAt
{
    BOOL result = [self printChannel:chan type:type nick:nick text:text identified:identified timestamp:receivedAt];
    if ([self needPrintConsole:chan]) {
        [self printConsole:chan type:type nick:nick text:text identified:identified timestamp:receivedAt];
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
        format = _world.viewTheme.other.logNickFormat;
    }

    NSString* s = format;

    if ([s contains:@"%@"]) {
        char mark = INVALID_MARK_CHAR;
        if (channel && !channel.isClient && channel.isChannel) {
            IRCUser* m = [channel findMember:nick];
            if (m) {
                mark = m.mark;
            }
        }
        s = [s stringByReplacingOccurrencesOfString:@"%@" withString:[NSString stringWithFormat:@"%c", mark]];
    }

    static NSRegularExpression* nickPattern = nil;
    if (!nickPattern) {
        nickPattern = [[NSRegularExpression alloc] initWithPattern:@"%(-?[0-9]+)?n" options:0 error:NULL];
    }

    while (1) {
        NSTextCheckingResult* result = [nickPattern firstMatchInString:s options:0 range:NSMakeRange(0, s.length)];
        if (!result || result.numberOfRanges < 2) {
            break;
        }

        NSRange r = [result rangeAtIndex:0];
        NSRange numRange = [result rangeAtIndex:1];

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

- (void)printConsole:(id)chan type:(LogLineType)type text:(NSString*)text timestamp:(time_t)receivedAt
{
    [self printConsole:chan type:type nick:nil text:text identified:NO timestamp:receivedAt];
}

- (void)printConsole:(id)chan type:(LogLineType)type nick:(NSString*)nick text:(NSString*)text identified:(BOOL)identified timestamp:(time_t)receivedAt
{
    NSString* time = [self formatTimestamp:receivedAt];
    IRCChannel* channel = nil;
    NSString* channelName = nil;
    NSString* place = nil;
    NSString* nickStr = nil;
    LogMemberType memberType = MEMBER_TYPE_NORMAL;
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
        place = [NSString stringWithFormat:@"<%@> ", _config.name];
    }

    if (nick.length > 0) {
        if (type == LINE_TYPE_ACTION) {
            nickStr = [NSString stringWithFormat:@"%@ ", nick];
        }
        else {
            nickStr = [self formatNick:nick channel:channel];
        }
    }

    if (nick && [nick isEqualToString:_myNick]) {
        memberType = MEMBER_TYPE_MYSELF;
    }

    if (nick && channel) {
        IRCUser* user = [channel findMember:nick];
        if (user) {
            colorNumber = user.colorNumber;
        }
    }

    if (channel) {
        clickContext = [NSString stringWithFormat:@"channel %d %d", self.uid, channel.uid];
    }
    else {
        clickContext = [NSString stringWithFormat:@"client %d", self.uid];
    }

    if (type == LINE_TYPE_PRIVMSG || type == LINE_TYPE_ACTION) {
        if (memberType != MEMBER_TYPE_MYSELF) {
            keywords = [Preferences keywords];
            excludeWords = [Preferences excludeWords];

            if ([Preferences keywordCurrentNick]) {
                NSMutableArray* ary = [keywords mutableCopy];
                [ary insertObject:_myNick atIndex:0];
                keywords = ary;
            }
        }
    }

    LogLine* c = [LogLine new];
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

    [_world.consoleLog print:c];
}

- (BOOL)printChannel:(id)chan type:(LogLineType)type text:(NSString*)text timestamp:(time_t)receivedAt
{
    return [self printChannel:chan type:type nick:nil text:text identified:NO timestamp:receivedAt];
}

- (BOOL)printChannel:(id)chan type:(LogLineType)type nick:(NSString*)nick text:(NSString*)text identified:(BOOL)identified timestamp:(time_t)receivedAt
{
    NSString* time = [self formatTimestamp:receivedAt];
    IRCChannel* channel = nil;
    NSString* place = nil;
    NSString* nickStr = nil;
    LogMemberType memberType = MEMBER_TYPE_NORMAL;
    int colorNumber = 0;
    NSArray* keywords = nil;
    NSArray* excludeWords = nil;

    if (time.length) {
        time = [time stringByAppendingString:@" "];
    }

    if ([chan isKindOfClass:[IRCChannel class]]) {
        channel = chan;
    }
    else if ([chan isKindOfClass:[NSString class]]) {
        place = [NSString stringWithFormat:@"<%@> ", chan];
    }

    if (nick.length > 0) {
        if (type == LINE_TYPE_ACTION) {
            nickStr = [NSString stringWithFormat:@"%@ ", nick];
        }
        else {
            nickStr = [self formatNick:nick channel:channel];
        }
    }

    if (nick && [nick isEqualToString:_myNick]) {
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
                NSMutableArray* ary = [keywords mutableCopy];
                [ary insertObject:_myNick atIndex:0];
                keywords = ary;
            }
        }
    }

    LogLine* c = [LogLine new];
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

    if (channel) {
        return [channel print:c];
    }
    else {
        return [self.log print:c];
    }
}

- (void)printSystem:(id)channel text:(NSString*)text
{
    time_t receivedAt;
    time(&receivedAt);
    [self printSystem:channel text:text timestamp:receivedAt];
}

- (void)printSystem:(id)channel text:(NSString*)text timestamp:(time_t)receivedAt
{
    [self printChannel:channel type:LINE_TYPE_SYSTEM text:text timestamp:receivedAt];
}

- (void)printSystemBoth:(id)channel text:(NSString*)text
{
    time_t receivedAt;
    time(&receivedAt);
    [self printSystemBoth:channel text:text timestamp:receivedAt];
}

- (void)printSystemBoth:(id)channel text:(NSString*)text timestamp:(time_t)receivedAt
{
    [self printBoth:channel type:LINE_TYPE_SYSTEM text:text timestamp:receivedAt];
}

- (void)printReply:(IRCMessage*)m
{
    NSString* text = [m sequence:1];
    [self printBoth:nil type:LINE_TYPE_REPLY text:text timestamp:m.timestamp];
}

- (void)printUnknownReply:(IRCMessage*)m
{
    NSString* text = [NSString stringWithFormat:@"Reply(%d): %@", m.numericReply, [m sequence:1]];
    [self printBoth:nil type:LINE_TYPE_REPLY text:text timestamp:m.timestamp];
}

- (void)printErrorReply:(IRCMessage*)m
{
    [self printErrorReply:m channel:nil];
}

- (void)printErrorReply:(IRCMessage*)m channel:(IRCChannel*)channel
{
    NSString* text = [NSString stringWithFormat:@"Error(%d): %@", m.numericReply, [m sequence:1]];
    [self printBoth:channel type:LINE_TYPE_ERROR_REPLY text:text timestamp:m.timestamp];
}

- (void)printError:(NSString*)error
{
    [self printBoth:nil type:LINE_TYPE_ERROR text:error];
}

- (void)printError:(NSString*)error timestamp:(time_t)receivedAt
{
    [self printBoth:nil type:LINE_TYPE_ERROR text:error timestamp:receivedAt];
}

#pragma mark - IRCTreeItem

- (BOOL)isClient
{
    return YES;
}

- (BOOL)isActive
{
    return _isLoggedIn;
}

- (IRCClient*)client
{
    return self;
}

- (int)numberOfChildren
{
    return _channels.count;
}

- (id)childAtIndex:(int)index
{
    return [_channels objectAtIndex:index];
}

- (NSString*)label
{
    return _config.name;
}

#pragma mark - WhoisDialog

- (WhoisDialog*)createWhoisDialogWithNick:(NSString*)nick username:(NSString*)username address:(NSString*)address realname:(NSString*)realname
{
    WhoisDialog* d = [self findWhoisDialog:nick];
    if (d) {
        [d show];
        return d;
    }

    d = [WhoisDialog new];
    d.delegate = self;
    [_whoisDialogs addObject:d];
    [d startWithNick:nick username:username address:address realname:realname];
    return d;
}

- (WhoisDialog*)findWhoisDialog:(NSString*)nick
{
    for (WhoisDialog* d in _whoisDialogs) {
        if ([nick isEqualNoCase:d.nick]) {
            return d;
        }
    }
    return nil;
}

- (void)whoisDialogOnTalk:(WhoisDialog*)sender
{
    IRCChannel* c = [_world createTalk:sender.nick client:self];
    if (c) {
        [_world select:c];
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
    [_whoisDialogs removeObjectIdenticalTo:sender];
}

#pragma mark - HostResolver Delegate

- (void)hostResolver:(HostResolver*)sender didResolve:(NSHost*)host
{
    NSArray* addresses = [host addresses];
    if (addresses.count) {
        _myAddress = [addresses objectAtIndex:0];
    }
}

- (void)hostResolver:(HostResolver*)sender didNotResolve:(NSString*)hostname
{
}

#pragma mark - Protocol Handlers

- (void)receivePrivmsgAndNotice:(IRCMessage*)m
{
    NSString* text = [m paramAt:1];

    BOOL identified = NO;
    if (_identifyCTCP && ([text hasPrefix:@"+\x01"] || [text hasPrefix:@"-\x01"])) {
        identified = [text hasPrefix:@"+"];
        text = [text substringFromIndex:1];
    }
    else if (_identifyMsg && ([text hasPrefix:@"+"] || [text hasPrefix:@"-"])) {
        identified = [text hasPrefix:@"+"];
        text = [text substringFromIndex:1];
    }

    if ([text hasPrefix:@"\x01"]) {
        //
        // CTCP
        //
        text = [text substringFromIndex:1];
        int n = [text findCharacter:0x1];
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
        BOOL keyword = [self printBoth:(c ?: (id)target) type:type nick:nick text:text identified:identified timestamp:m.timestamp];

        if (type == LINE_TYPE_NOTICE) {
            [self notifyText:USER_NOTIFICATION_CHANNEL_NOTICE target:(c ?: (id)target) nick:nick text:text];
            [SoundPlayer play:[Preferences soundForEvent:USER_NOTIFICATION_CHANNEL_NOTICE]];
        }
        else {
            id t = c ?: (id)self;
            [self setUnreadState:t];
            if (keyword) [self setKeywordState:t];

            UserNotificationType kind = keyword ? USER_NOTIFICATION_HIGHLIGHT : USER_NOTIFICATION_CHANNEL_MSG;
            [self notifyText:kind target:(c ?: (id)target) nick:nick text:text];
            [SoundPlayer play:[Preferences soundForEvent:kind]];

            if (c) {
                // track the conversation to nick complete
                IRCUser* sender = [c findMember:nick];
                if (sender) {
                    static NSCharacterSet* underlineSet = nil;
                    if (!underlineSet) {
                        underlineSet = [NSCharacterSet characterSetWithCharactersInString:@"_"];
                    }
                    NSString* trimmedMyNick = [_myNick stringByTrimmingCharactersInSet:underlineSet];
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
    else if ([target isEqualNoCase:_myNick]) {
        if (!nick.length || [nick contains:@"."]) {
            // system
            [self printBoth:nil type:type text:text timestamp:m.timestamp];
        }
        else {
            // talk
            IRCChannel* c = [self findChannel:nick];
            BOOL newTalk = NO;
            BOOL moreTalk = NO;
            if (!c && type != LINE_TYPE_NOTICE) {
                c = [_world createTalk:nick client:self];
                newTalk = YES;
            }
            else if (c && type != LINE_TYPE_NOTICE && [Preferences bounceIconOnEveryPrivateMessage]) {
                moreTalk = YES;
            }

            BOOL keyword = [self printBoth:c type:type nick:nick text:text identified:identified timestamp:m.timestamp];

            if (type == LINE_TYPE_NOTICE) {
                if ([nick isEqualNoCase:@"NickServ"]) {
                    if (_registeringToNickServ) {
                        if ([text hasPrefix:@"You are now identified for "]
                            || [text hasPrefix:@"Invalid password for "]
                            || [text hasSuffix:@" is not a registered nickname."]) {
                            [self performAutoJoin];
                        }
                    }
                    else {
                        if ([text hasPrefix:@"This nickname is registered."]) {
                            if (_config.nickPassword.length) {
                                [self send:PRIVMSG, @"NickServ", [NSString stringWithFormat:@"IDENTIFY %@", _config.nickPassword], nil];
                            }
                        }
                    }
                }

                [self notifyText:USER_NOTIFICATION_TALK_NOTICE target:(c ?: (id)target) nick:nick text:text];
                [SoundPlayer play:[Preferences soundForEvent:USER_NOTIFICATION_TALK_NOTICE]];
            }
            else {
                id t = c ?: (id)self;
                [self setUnreadState:t];
                if (keyword) [self setKeywordState:t];
                if (newTalk || moreTalk) [self setNewTalkState:t];

                UserNotificationType kind = keyword ? USER_NOTIFICATION_HIGHLIGHT : newTalk ? USER_NOTIFICATION_NEW_TALK : USER_NOTIFICATION_TALK_MSG;
                [self notifyText:kind target:(c ?: (id)target) nick:nick text:text];
                [SoundPlayer play:[Preferences soundForEvent:kind]];
            }
        }
    }
    else {
        // system
        if (!nick.length || [nick contains:@"."]) {
            [self printBoth:nil type:type text:text timestamp:m.timestamp];
        }
        else {
            [self printBoth:nil type:type nick:nick text:text identified:identified timestamp:m.timestamp];
        }
    }
}

- (void)receiveCTCPQuery:(IRCMessage*)m text:(NSString*)text
{
    //LOG(@"CTCP Query: %@", text);

    NSString* nick = m.sender.nick;
    NSMutableString* s = [text mutableCopy];
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
        [self printBoth:nil type:LINE_TYPE_REPLY text:text timestamp:m.timestamp];
    }
    else {
        CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
        if (now - _lastCTCPTime < CTCP_MIN_INTERVAL) {
            NSString* text = [NSString stringWithFormat:@"CTCP-query %@ from %@ was ignored", command, nick];
            [self printBoth:nil type:LINE_TYPE_REPLY text:text timestamp:m.timestamp];
            return;
        }
        _lastCTCPTime = now;

        NSString* text = [NSString stringWithFormat:@"CTCP-query %@ from %@", command, nick];
        [self printBoth:nil type:LINE_TYPE_REPLY text:text timestamp:m.timestamp];

        if ([command isEqualToString:PING]) {
            [self sendCTCPReply:nick command:command text:s];
        }
        else if ([command isEqualToString:TIME]) {
            NSDateFormatter* formatter = [NSDateFormatter new];
            NSLocale* locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
            [formatter setLocale:locale];
            [formatter setDateFormat:@"yyyy/MM/dd HH:mm Z"];
            NSString* text = [formatter stringFromDate:[NSDate date]];
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
            [self sendCTCPReply:nick command:command text:_config.userInfo ?: @""];
        }
        else if ([command isEqualToString:CLIENTINFO]) {
            [self sendCTCPReply:nick command:command text:NSLocalizedString(@"CTCPClientInfo", nil)];
        }
    }
}

- (void)receiveCTCPReply:(IRCMessage*)m text:(NSString*)text
{
    NSString* nick = m.sender.nick;
    NSMutableString* s = [text mutableCopy];
    NSString* command = [[s getToken] uppercaseString];

    if ([self checkIgnore:nil nick:nick channel:nil]) {
        return;
    }

    if ([command isEqualToString:PING]) {
        double time = [s doubleValue];
        double delta = CFAbsoluteTimeGetCurrent() - time;

        NSString* text = [NSString stringWithFormat:@"CTCP-reply %@ from %@ : %1.2f sec", command, nick, delta];
        [self printBoth:nil type:LINE_TYPE_REPLY text:text timestamp:m.timestamp];
    }
    else {
        NSString* text = [NSString stringWithFormat:@"CTCP-reply %@ from %@ : %@", command, nick, s];
        [self printBoth:nil type:LINE_TYPE_REPLY text:text timestamp:m.timestamp];
    }
}

- (void)receiveDCCSend:(IRCMessage*)m fileName:(NSString*)fileName address:(NSString*)address port:(int)port fileSize:(long long)size
{
    NSString* nick = m.sender.nick;
    NSString* target = [m paramAt:0];

    if (![target isEqualToString:_myNick]) return;

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
    [self printBoth:nil type:LINE_TYPE_DCC_SEND_RECEIVE text:text timestamp:m.timestamp];

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

            [_world.dcc addReceiverWithUID:self.uid nick:nick host:host port:port path:path fileName:fileName size:size];

            [self notifyEvent:USER_NOTIFICATION_FILE_RECEIVE_REQUEST target:nil nick:nick text:fileName];
            [SoundPlayer play:[Preferences soundForEvent:USER_NOTIFICATION_FILE_RECEIVE_REQUEST]];

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

    BOOL myself = [nick isEqualNoCase:_myNick];

    // work around for ircd 2.9.5
    BOOL njoin = NO;
    if ([chname hasSuffix:@"\x07o"]) {
        njoin = YES;
        chname = [chname substringToIndex:chname.length - 2];
    }

    IRCChannel* c = [self findChannel:chname];

    if (myself) {
        if (!c) {
            IRCChannelConfig* seed = [IRCChannelConfig new];
            seed.name = chname;
            seed.autoJoin = NO;
            c = [_world createChannel:seed client:self reload:YES adjust:YES];
            [_world save];
        }
        [c activate];
        [self reloadTree];
        [self printSystem:c text:@"You have joined the channel" timestamp:m.timestamp];

        if (!_joinMyAddress) {
            _joinMyAddress = m.sender.address;
            if (_addressDetectionMethod == ADDRESS_DETECT_JOIN) {
                if (_joinMyAddress.length) {
                    [_nameResolver resolve:_joinMyAddress];
                }
            }
        }

        if (_joiningChannelName) {
            CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
            if (now - _joinSentTime < 30) {
                if ([_joiningChannelName isEqualNoCase:chname]) {
                    [_world select:c];
                    _joiningChannelName = nil;
                }
            }
            else {
                _joiningChannelName = nil;
            }
        }
    }

    if (c) {
        IRCUser* u = [IRCUser new];
        u.isupport = _isupport;
        u.nick = nick;
        u.username = m.sender.user;
        u.address = m.sender.address;
        u.o = njoin;
        [c addMember:u];
        [self updateChannelTitle:c];
    }

    if ([Preferences showJoinLeave]) {
        NSString* text = [NSString stringWithFormat:@"%@ has joined (%@@%@)", nick, m.sender.user, m.sender.address];
        [self printBoth:(c ?: (id)chname) type:LINE_TYPE_JOIN text:text timestamp:m.timestamp];
    }

    //@@@ check auto op

    // add user to talk
    c = [self findChannel:nick];
    if (c) {
        IRCUser* u = [IRCUser new];
        u.isupport = _isupport;
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
        if ([nick isEqualNoCase:_myNick]) {
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
        [self printBoth:(c ?: (id)chname) type:LINE_TYPE_PART text:text timestamp:m.timestamp];
    }

    if (myself) {
        [self printSystem:c text:@"You have left the channel" timestamp:m.timestamp];
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
        BOOL myself = [target isEqualNoCase:_myNick];
        if (myself) {
            [c deactivate];
            [self reloadTree];
            [self printSystemBoth:c text:@"You have been kicked out of the channel" timestamp:m.timestamp];

            [self notifyEvent:USER_NOTIFICATION_KICKED target:c nick:nick text:comment];
            [SoundPlayer play:[Preferences soundForEvent:USER_NOTIFICATION_KICKED]];
        }

        [c removeMember:target];
        [self updateChannelTitle:c];
        [self checkRejoin:c];
    }

    NSString* text = [NSString stringWithFormat:@"%@ has kicked %@ (%@)", nick, target, comment];
    [self printBoth:(c ?: (id)chname) type:LINE_TYPE_KICK text:text timestamp:m.timestamp];
}

- (void)receiveQuit:(IRCMessage*)m
{
    NSString* nick = m.sender.nick;
    NSString* comment = [m paramAt:0];

    NSString* text = [NSString stringWithFormat:@"%@ has left IRC (%@)", nick, comment];

    for (IRCChannel* c in _channels) {
        if ([c findMember:nick]) {
            if ([Preferences showJoinLeave]) {
                [self printChannel:c type:LINE_TYPE_QUIT text:text timestamp:m.timestamp];
            }
            [c removeMember:nick];
            [self updateChannelTitle:c];
            [self checkRejoin:c];
        }
    }

    if ([Preferences showJoinLeave]) {
        [self printConsole:nil type:LINE_TYPE_QUIT text:text timestamp:m.timestamp];
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

    for (IRCChannel* c in _channels) {
        if ([c findMember:target]) {
            [self printChannel:c type:LINE_TYPE_KILL text:text timestamp:m.timestamp];
            [c removeMember:target];
            [self updateChannelTitle:c];
            [self checkRejoin:c];
        }
    }

    if ([Preferences showJoinLeave]) {
        [self printConsole:nil type:LINE_TYPE_KILL text:text timestamp:m.timestamp];
    }
}

- (void)receiveNick:(IRCMessage*)m
{
    NSString* nick = m.sender.nick;
    NSString* toNick = [m paramAt:0];

    if ([nick isEqualNoCase:_myNick]) {
        // changed my nick
        _myNick = toNick;
        [self updateClientTitle];

        if ([Preferences showRename]) {
            NSString* text = [NSString stringWithFormat:@"You are now known as %@", toNick];
            [self printChannel:nil type:LINE_TYPE_NICK text:text timestamp:m.timestamp];
        }
    }

    for (IRCChannel* c in _channels) {
        if ([c findMember:nick]) {
            // rename channel member
            if ([Preferences showRename]) {
                NSString* text = [NSString stringWithFormat:@"%@ is now known as %@", nick, toNick];
                [self printChannel:c type:LINE_TYPE_NICK text:text timestamp:m.timestamp];
            }
            [c renameMember:nick to:toNick];
        }
    }

    IRCChannel* c = [self findChannel:nick];
    if (c) {
        IRCChannel* t = [self findChannel:toNick];
        if (t) {
            // there is a channel already for a nick
            // just remove it
            [_world destroyChannel:t];
        }

        // rename talk
        c.name = toNick;
        [self reloadTree];
        [self updateChannelTitle:c];
    }

    // rename nick on whois dialogs
    for (WhoisDialog* d in _whoisDialogs) {
        if ([d.nick isEqualToString:nick]) {
            d.nick = toNick;
        }
    }

    // rename nick in dcc
    [_world.dcc nickChanged:nick toNick:toNick client:self];

    if ([Preferences showRename]) {
        NSString* text = [NSString stringWithFormat:@"%@ is now known as %@", nick, toNick];
        [self printConsole:nil type:LINE_TYPE_NICK text:text timestamp:m.timestamp];
    }
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
                    IRCUser* me = [c findMember:_myNick];
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

                if ((mode == 'q' || mode == 'a' || mode == 'o') && [_myNick isEqualNoCase:t]) {
                    // mode change for myself
                    IRCUser* m = [c findMember:_myNick];
                    if (m) {
                        myself = YES;
                        BOOL prev = m.isOp;
                        [c changeMember:_myNick mode:mode value:plus];
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
        [self printBoth:(c ?: (id)target) type:LINE_TYPE_MODE text:text timestamp:m.timestamp];
    }
    else {
        // user mode
        [_myMode update:modeStr];

        NSString* text = [NSString stringWithFormat:@"%@ has changed mode: %@", nick, modeStr];
        [self printBoth:nil type:LINE_TYPE_MODE text:text timestamp:m.timestamp];
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
    [self printBoth:(c ?: (id)chname) type:LINE_TYPE_TOPIC text:text timestamp:m.timestamp];
}

- (void)receiveInvite:(IRCMessage*)m
{
    NSString* nick = m.sender.nick;
    NSString* chname = [m paramAt:1];

    if ([self checkIgnore:nil nick:nick channel:chname]) {
        return;
    }

    NSString* text = [NSString stringWithFormat:@"%@ has invited you to %@", nick, chname];
    [self printBoth:self type:LINE_TYPE_INVITE text:text timestamp:m.timestamp];

    if ([Preferences autoJoinOnInvited]) {
        IRCChannel* c = [self findChannel:chname];
        if (!c) {
            IRCChannelConfig* seed = [IRCChannelConfig new];
            seed.name = chname;
            c = [_world createChannel:seed client:self reload:YES adjust:YES];
            [_world save];
            [self joinChannel:c];
        }
    } else {
        [self setKeywordState:self];
    }

    [self notifyEvent:USER_NOTIFICATION_INVITED target:nil nick:nick text:chname];
    [SoundPlayer play:[Preferences soundForEvent:USER_NOTIFICATION_INVITED]];
}

- (void)receiveError:(IRCMessage*)m
{
    [self printError:m.sequence timestamp:m.timestamp];
}

- (void)receivePing:(IRCMessage*)m
{
    [self send:PONG, [m sequence:0], nil];

    [self stopPongTimer];
    [self startPongTimer];
}

- (void)receiveCap:(IRCMessage*)m
{
    if (_isLoggedIn) return;

    NSString* command = [m paramAt:1];
    NSString* params = [[m paramAt:2] trim];

    if ([command isEqualNoCase:@"ack"]) {
        if ([params isEqualNoCase:@"sasl"]) {
            [self send:AUTHENTICATE, @"PLAIN", nil];
        }
    }
}

- (void)receiveAuthenticate:(IRCMessage*)m
{
    if (_isLoggedIn) return;

    NSString* command = [[m paramAt:0] trim];

    if ([command isEqualNoCase:@"+"]) {
        NSString* user = _config.username;
        NSString* pass = _config.nickPassword;
        if (!user.length) user = _config.nick;
        if (!pass.length) pass = @"";

        NSString* base = [NSString stringWithFormat:@"%@\0%@\0%@", _config.nick, user, pass];
        NSData* data = [base dataUsingEncoding:_encoding];
        NSString* authStr = [GTMBase64 stringByEncodingData:data];
        [self send:AUTHENTICATE, authStr, nil];
    }
}

- (void)receiveInit:(IRCMessage*)m
{
    if (_isLoggedIn) return;

    _isLoggedIn = YES;
    _conn.loggedIn = YES;
    _tryingNickNumber = -1;

    _registeringToNickServ = NO;
    _inWhois = NO;
    _inList = NO;

    [self startPongTimer];
    [self stopRetryTimer];
    [self stopAutoJoinTimer];

    [_world expandClient:self];

    _serverHostname = m.sender.raw;
    _myNick = [m paramAt:0];

    [self printSystem:self text:@"Logged in" timestamp:m.timestamp];

    [self notifyEvent:USER_NOTIFICATION_LOGIN];
    [SoundPlayer play:[Preferences soundForEvent:USER_NOTIFICATION_LOGIN]];

    if (!_isRegisteredWithSASL && _config.nickPassword.length) {
        _registeringToNickServ = YES;
        [self startAutoJoinTimer];
        [self send:PRIVMSG, @"NickServ", [NSString stringWithFormat:@"IDENTIFY %@", _config.nickPassword], nil];
    }

    for (NSString* command in _config.loginCommands) {
        NSString* s = command;
        if ([s hasPrefix:@"/"]) {
            s = [s substringFromIndex:1];
        }
        [self sendCommand:s completeTarget:NO target:nil];
    }

    for (IRCChannel* c in _channels) {
        if (c.isTalk) {
            [c activate];

            IRCUser* m;
            m = [IRCUser new];
            m.isupport = _isupport;
            m.nick = _myNick;
            [c addMember:m];

            m = [IRCUser new];
            m.isupport = _isupport;
            m.nick = c.name;
            [c addMember:m];
        }
    }

    [self updateClientTitle];
    [self reloadTree];

    if (!_registeringToNickServ) {
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
            [_isupport update:[m sequence:1]];
            [self printReply:m];
            break;
        case 221:	// RPL_UMODEIS
        {
            NSString* modeStr = [m paramAt:1];

            modeStr = [modeStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if ([modeStr isEqualToString:@"+"]) return;

            [_myMode clear];
            [_myMode update:modeStr];
            [self updateClientTitle];

            NSString* text = [NSString stringWithFormat:@"Mode: %@", modeStr];
            [self printBoth:nil type:LINE_TYPE_REPLY text:text timestamp:m.timestamp];
            break;
        }
        case 290:	// RPL_CAPAB on freenode
        {
            NSString* kind = [m paramAt:1];
            kind = [kind lowercaseString];

            if ([kind isEqualToString:@"identify-msg"]) {
                _identifyMsg = YES;
            }
            else if ([kind isEqualToString:@"identify-ctcp"]) {
                _identifyCTCP = YES;
            }

            [self printReply:m];
            break;
        }
        case 301:	// RPL_AWAY
        {
            NSString* nick = [m paramAt:1];
            NSString* comment = [m paramAt:2];

            if (_inWhois) {
                WhoisDialog* d = [self findWhoisDialog:nick];
                if (d) {
                    [d setAwayMessage:comment];
                    return;
                }
            }

            IRCChannel* c = [self findChannel:nick];
            NSString* text = [NSString stringWithFormat:@"%@ is away: %@", nick, comment];
            [self printBoth:(c ?: (id)nick) type:LINE_TYPE_REPLY text:text timestamp:m.timestamp];
            break;
        }
        case 311:	// RPL_WHOISUSER
        {
            NSString* nick = [m paramAt:1];
            NSString* username = [m paramAt:2];
            NSString* address = [m paramAt:3];
            NSString* realname = [m paramAt:5];

            _inWhois = YES;

            WhoisDialog* d = [self createWhoisDialogWithNick:nick username:username address:address realname:realname];
            if (!d) {
                NSString* text = [NSString stringWithFormat:@"%@ is %@ (%@@%@)", nick, realname, username, address];
                [self printBoth:nil type:LINE_TYPE_REPLY text:text timestamp:m.timestamp];
            }
            break;
        }
        case 312:	// RPL_WHOISSERVER
        {
            NSString* nick = [m paramAt:1];
            NSString* server = [m paramAt:2];
            NSString* serverInfo = [m paramAt:3];

            if (_inWhois) {
                WhoisDialog* d = [self findWhoisDialog:nick];
                if (d) {
                    [d setServer:server serverInfo:serverInfo];
                    return;
                }
            }

            NSString* text = [NSString stringWithFormat:@"%@ is on %@ (%@)", nick, server, serverInfo];
            [self printBoth:nil type:LINE_TYPE_REPLY text:text timestamp:m.timestamp];
            break;
        }
        case 313:	// RPL_WHOISOPERATOR
        {
            NSString* nick = [m paramAt:1];

            if (_inWhois) {
                WhoisDialog* d = [self findWhoisDialog:nick];
                if (d) {
                    [d setIsOperator:YES];
                    return;
                }
            }

            NSString* text = [NSString stringWithFormat:@"%@ is an IRC operator", nick];
            [self printBoth:nil type:LINE_TYPE_REPLY text:text timestamp:m.timestamp];
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
                signOn = [[IRCClient dateTimeFormatter] stringFromDate:date];
            }

            if (_inWhois) {
                WhoisDialog* d = [self findWhoisDialog:nick];
                if (d) {
                    [d setIdle:idle signOn:signOn];
                    return;
                }
            }

            NSString* text;
            text = [NSString stringWithFormat:@"%@ is %@ idle", nick, idle];
            [self printBoth:nil type:LINE_TYPE_REPLY text:text timestamp:m.timestamp];
            text = [NSString stringWithFormat:@"%@ logged in at %@", nick, signOn];
            [self printBoth:nil type:LINE_TYPE_REPLY text:text timestamp:m.timestamp];
            break;
        }
        case 319:	// RPL_WHOISCHANNELS
        {
            NSString* nick = [m paramAt:1];
            NSString* trail = [m paramAt:2];

            trail = [trail stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            NSArray* channelNames = [trail componentsSeparatedByString:@" "];

            if (_inWhois) {
                WhoisDialog* d = [self findWhoisDialog:nick];
                if (d) {
                    [d setChannels:channelNames];
                    return;
                }
            }

            NSString* text = [NSString stringWithFormat:@"%@ is in %@", nick, trail];
            [self printBoth:nil type:LINE_TYPE_REPLY text:text timestamp:m.timestamp];
            break;
        }
        case 318:	// RPL_ENDOFWHOIS
            _inWhois = NO;
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
                        IRCUser* me = [c findMember:_myNick];
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
            [self printBoth:(c ?: (id)chname) type:LINE_TYPE_REPLY text:text timestamp:m.timestamp];
            break;
        }
        case 329:	// hemp ? channel creation time
        {
            NSString* chname = [m paramAt:1];
            NSString* timeStr = [m paramAt:2];
            long long timeNum = [timeStr longLongValue];

            IRCChannel* c = [self findChannel:chname];
            NSString* text = [NSString stringWithFormat:@"Created at: %@", [[IRCClient dateTimeFormatter] stringFromDate:[NSDate dateWithTimeIntervalSince1970:timeNum]]];
            [self printBoth:(c ?: (id)chname) type:LINE_TYPE_REPLY text:text timestamp:m.timestamp];
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
            [self printBoth:(c ?: (id)chname) type:LINE_TYPE_REPLY text:text timestamp:m.timestamp];
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
            [self printBoth:(c ?: (id)chname) type:LINE_TYPE_REPLY text:text timestamp:m.timestamp];
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
                set = [NSCharacterSet characterSetWithCharactersInString:@"!@"];
            }
            NSRange r = [setter rangeOfCharacterFromSet:set];
            if (r.location != NSNotFound) {
                setter = [setter substringToIndex:r.location];
            }

            IRCChannel* c = [self findChannel:chname];
            NSString* text = [NSString stringWithFormat:@"%@ set the topic at: %@", setter, [[IRCClient dateTimeFormatter] stringFromDate:[NSDate dateWithTimeIntervalSince1970:timeNum]]];
            [self printBoth:(c ?: (id)chname) type:LINE_TYPE_REPLY text:text timestamp:m.timestamp];
            break;
        }
        case 341:	// RPL_INVITING
        {
            NSString* nick = [m paramAt:1];
            NSString* chname = [m paramAt:2];

            NSString* text = [NSString stringWithFormat:@"Inviting %@ to %@", nick, chname];
            [self printBoth:nil type:LINE_TYPE_REPLY text:text timestamp:m.timestamp];
            break;
        }
        case 353:	// RPL_NAMREPLY
        {
            NSString* chname = [m paramAt:2];
            NSString* trail = [m paramAt:3];

            IRCChannel* c = [self findChannel:chname];
            if (c && c.isActive && !c.isNamesInit) {
                NSArray* ary = [trail componentsSeparatedByString:@" "];
                for (NSString* nickItem in ary) {
                    NSString* nick = nickItem;
                    if (!nick.length) continue;
                    char opMark = [nick characterAtIndex:0];
                    char mode = [_isupport modeForMark:opMark];
                    if (mode != INVALID_MODE_CHAR) {
                        nick = [nick substringFromIndex:1];
                    }

                    IRCUser* m = [IRCUser new];
                    m.isupport = _isupport;
                    m.nick = nick;
                    m.q = (mode == 'q');
                    m.a = (mode == 'a');
                    m.o = (mode == 'o') || m.q;
                    m.h = (mode == 'h');
                    m.v = (mode == 'v');
                    m.isMyself = [nick isEqualNoCase:_myNick];
                    [c addMember:m reload:NO];
                    if ([_myNick isEqualNoCase:nick]) {
                        c.isOp = (m.q || m.a | m.o);
                    }
                }
                [c reloadMemberList];
                [self updateChannelTitle:c];
            }
            else {
                [self printBoth:c ?: (id)chname type:LINE_TYPE_REPLY text:[NSString stringWithFormat:@"Names: %@", trail] timestamp:m.timestamp];
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

            if (!_inList) {
                _inList = YES;
                if (_channelListDialog) {
                    [_channelListDialog clear];
                }
                else {
                    [self createChannelListDialog];
                }
            }

            if (_channelListDialog) {
                [_channelListDialog addChannel:chname count:[countStr intValue] topic:topic];
            }
            else {
                NSString* text = [NSString stringWithFormat:@"%@ (%@) %@", chname, countStr, topic];
                [self printBoth:nil type:LINE_TYPE_REPLY text:text timestamp:m.timestamp];
            }
            break;
        }
        case 323:	// RPL_LISTEND
            _inList = NO;
            break;
        case 900:	// SASL logged in
        {
            _isRegisteredWithSASL = YES;
            NSString* text = [m sequence:3];
            [self printBoth:nil type:LINE_TYPE_REPLY text:text timestamp:m.timestamp];
            break;
        }
        case 903:	// SASL authentication successful
            [self printReply:m];
            [self send:CAP, @"END", nil];
            break;
        case 904:	// SASL authentication failed
            [self printReply:m];
            [self send:CAP, @"END", nil];
            break;
        case 906:	// SASL authentication aborted
            [self printReply:m];
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

            if (_registeringToNickServ && [nick isEqualNoCase:@"NickServ"]) {
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
    if (_config.altNicks.count && !_isLoggedIn) {
        // only works when not logged in
        ++_tryingNickNumber;
        NSArray* altNicks = _config.altNicks;

        if (_tryingNickNumber < altNicks.count) {
            NSString* nick = [altNicks objectAtIndex:_tryingNickNumber];
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
    if (_sentNick.length >= _isupport.nickLen) {
        NSString* nick = [_sentNick substringToIndex:_isupport.nickLen];
        BOOL found = NO;

        for (int i=nick.length-1; i>=0; --i) {
            UniChar c = [nick characterAtIndex:i];
            if (c != '_') {
                found = YES;
                NSString* head = [nick substringToIndex:i];
                NSMutableString* s = [head mutableCopy];
                for (int i=_isupport.nickLen - s.length; i>0; --i) {
                    [s appendString:@"_"];
                }
                _sentNick = s;
                break;
            }
        }

        if (!found) {
            _sentNick = @"0";
        }
    }
    else {
        _sentNick = [_sentNick stringByAppendingString:@"_"];
    }

    [self send:NICK, _sentNick, nil];
}

#pragma mark - IRCConnection Delegate

- (void)changeStateOff
{
    BOOL prevConnected = _isConnected;

    _conn = nil;

    [self clearCommandQueue];
    [self stopPongTimer];
    [self stopQuitTimer];
    [self stopRetryTimer];

    if (_reconnectEnabled) {
        [self startReconnectTimer];
    }

    _isConnecting = _isConnected = _isLoggedIn = _isQuitting = NO;
    _myNick = @"";
    _sentNick = @"";

    _tryingNickNumber = -1;
    _joinMyAddress = nil;
    _joinSentTime = 0;
    _joiningChannelName = nil;

    _inWhois = NO;
    _inList = NO;
    _identifyMsg = NO;
    _identifyCTCP = NO;

    for (IRCChannel* c in _channels) {
        if (c.isActive) {
            [c deactivate];
            [self printSystem:c text:@"Disconnected"];
        }
    }

    [self printSystemBoth:nil text:@"Disconnected"];

    [self updateClientTitle];
    [self reloadTree];

    if (prevConnected) {
        [self notifyEvent:USER_NOTIFICATION_DISCONNECT];
        [SoundPlayer play:[Preferences soundForEvent:USER_NOTIFICATION_DISCONNECT]];
    }
}

- (void)ircConnectionDidConnect:(IRCConnection*)sender
{
    [self startRetryTimer];

    [self printSystemBoth:nil text:@"Connected"];

    _isConnecting = _isLoggedIn = NO;
    _isConnected = _reconnectEnabled = YES;
    _encoding = _config.encoding;
    _isRegisteredWithSASL = NO;

    if (!_inputNick.length) {
        _inputNick = _config.nick;
    }
    _sentNick = _inputNick;
    _myNick = _inputNick;

    [_isupport reset];
    [_myMode clear];

    int modeParam = _config.invisibleMode ? 8 : 0;
    NSString* user = _config.username;
    NSString* realName = _config.realName;
    if (!user.length) user = _config.nick;
    if (!realName.length) realName = _config.nick;

    if (_config.useSASL) {
        // If you send REQ to some servers (hyperion or etc) before PASS, the server refuses connection.
        // To avoid this, do not send REQ if SASL setting is off.
        [self send:CAP, @"REQ", @"znc.in/server-time", nil];
        [self send:CAP, @"REQ", @"znc.in/server-time-iso", nil];

        if (_config.nick.length && _config.nickPassword.length) {
            [self send:CAP, @"REQ", @"sasl", nil];
        }
    }

    if (_config.password.length) {
        [self send:PASS, _config.password, nil];
    }

    [self send:NICK, _sentNick, nil];
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
    NSStringEncoding enc = _encoding;
    if (_encoding == NSUTF8StringEncoding && _config.fallbackEncoding != NSUTF8StringEncoding && ![data isValidUTF8]) {
        enc = _config.fallbackEncoding;
    }

    if (_encoding == NSISO2022JPStringEncoding) {
        data = [data convertKanaFromNativeToISO2022];
    }

    NSString* s = [[NSString alloc] initWithData:data encoding:enc];
    if (!s) {
        if (_encoding == NSISO2022JPStringEncoding) {
            // avoid incomplete sequence
            NSMutableData* d = [data mutableCopy];
            while (d.length > 1) {
                [d setLength:d.length - 1];
                s = [[NSString alloc] initWithData:d encoding:enc];
                if (s) break;
            }
        }

        if (!s) {
            s = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
            if (!s) return;
        }
    }

    IRCMessage* m = [[IRCMessage alloc] initWithLine:s];
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
    else if ([cmd isEqualToString:CAP]) [self receiveCap:m];
    else if ([cmd isEqualToString:AUTHENTICATE]) [self receiveAuthenticate:m];
}

- (void)ircConnectionWillSend:(NSString*)line
{
}

#pragma mark - Class Method

+ (NSDateFormatter*)dateTimeFormatter
{
    static NSDateFormatter* dateTimeFormatter = nil;

    if (!dateTimeFormatter) {
        dateTimeFormatter = [NSDateFormatter new];
        [dateTimeFormatter setDateStyle:NSDateFormatterMediumStyle];
        [dateTimeFormatter setTimeStyle:NSDateFormatterShortStyle];
    }
    return dateTimeFormatter;
}

@end
