// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "IRCConnection.h"
#include <SystemConfiguration/SystemConfiguration.h>
#import "IRC.h"
#import "NSData+Kana.h"


#define TIMER_INTERVAL      2
#define PENALTY_THREASHOLD  5


@implementation IRCConnection
{
    TCPClient* _conn;
    NSMutableArray* _sendQueue;
    Timer* _timer;
    BOOL _sending;
    int _penalty;
}

- (id)init
{
    self = [super init];
    if (self) {
        _encoding = NSUTF8StringEncoding;
        _sendQueue = [NSMutableArray new];
        _timer = [Timer new];
        _timer.delegate = self;
    }
    return self;
}

- (void)dealloc
{
    [_conn close];
    [_timer stop];
}

- (void)open
{
    [self close];

    _conn = [TCPClient new];
    _conn.delegate = self;
    _conn.host = _host;
    _conn.port = _port;
    _conn.useSSL = _useSSL;

    if (_useSystemSocks) {
        // check if system socks proxy is enabled
        CFDictionaryRef proxyDic = SCDynamicStoreCopyProxies(NULL);
        NSNumber* num = (NSNumber*)CFDictionaryGetValue(proxyDic, kSCPropNetProxiesSOCKSEnable);
        BOOL systemSocksEnabled = [num intValue] != 0;
        CFRelease(proxyDic);

        _conn.useSocks = systemSocksEnabled;
        _conn.useSystemSocks = systemSocksEnabled;
    }
    else {
        _conn.useSocks = _useSocks;
        _conn.socksVersion = _socksVersion;
    }

    _conn.proxyHost = _proxyHost;
    _conn.proxyPort = _proxyPort;
    _conn.proxyUser = _proxyUser;

    [_conn open];
}

- (void)close
{
    _loggedIn = NO;
    [_timer stop];
    [_sendQueue removeAllObjects];
    [_conn close];
    _conn = nil;
}

- (BOOL)active
{
    return [_conn active];
}

- (BOOL)connecting
{
    return [_conn connecting];
}

- (BOOL)connected
{
    return [_conn connected];
}

- (BOOL)readyToSend
{
    return !_sending && _penalty == 0;
}

- (void)clearSendQueue
{
    [_sendQueue removeAllObjects];
    [self updateTimer];
}

- (void)sendLine:(NSString*)line
{
    [_sendQueue addObject:line];
    [self tryToSend];
    [self updateTimer];
}

- (NSData*)convertToCommonEncoding:(NSString*)s
{
    NSData* data = [s dataUsingEncoding:_encoding];
    if (!data) {
        data = [s dataUsingEncoding:_encoding allowLossyConversion:YES];
        if (!data) {
            data = [s dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
        }
    }

    if (_encoding == NSISO2022JPStringEncoding) {
        if (data) {
            data = [data convertKanaFromISO2022ToNative];
        }
    }

    return data;
}

- (void)tryToSend
{
    if ([_sendQueue count] == 0) return;
    if (_sending) return;
    if (_penalty > PENALTY_THREASHOLD) return;

    NSString* s = [_sendQueue objectAtIndex:0];
    s = [s stringByAppendingString:@"\r\n"];
    [_sendQueue removeObjectAtIndex:0];

    NSData* data = [self convertToCommonEncoding:s];

    if (data) {
        _sending = YES;
        if (_loggedIn) {
            _penalty += IRC_PENALTY_NORMAL;
        }

        [_conn write:data];

        if ([_delegate respondsToSelector:@selector(ircConnectionWillSend:)]) {
            [_delegate ircConnectionWillSend:s];
        }
    }
}

- (void)updateTimer
{
    if (!_sendQueue.count && _penalty <= 0) {
        if (_timer.isActive) {
            [_timer stop];
        }
    }
    else {
        if (!_timer.isActive) {
            [_timer start:TIMER_INTERVAL];
        }
    }
}

- (void)timerOnTimer:(id)sender
{
    if (_penalty > 0) _penalty -= TIMER_INTERVAL;
    if (_penalty < 0) _penalty = 0;
    [self tryToSend];
    [self updateTimer];
}

- (void)tcpClientDidConnect:(TCPClient*)sender
{
    [_sendQueue removeAllObjects];

    if ([_delegate respondsToSelector:@selector(ircConnectionDidConnect:)]) {
        [_delegate ircConnectionDidConnect:self];
    }
}

- (void)tcpClient:(TCPClient*)sender error:(NSString*)error
{
    [_timer stop];
    [_sendQueue removeAllObjects];

    if ([_delegate respondsToSelector:@selector(ircConnectionDidError:)]) {
        [_delegate ircConnectionDidError:error];
    }
}

- (void)tcpClientDidDisconnect:(TCPClient*)sender
{
    [_timer stop];
    [_sendQueue removeAllObjects];

    if ([_delegate respondsToSelector:@selector(ircConnectionDidDisconnect:)]) {
        [_delegate ircConnectionDidDisconnect:self];
    }
}

- (void)tcpClientDidReceiveData:(TCPClient*)sender
{
    while (1) {
        NSData* data = [_conn readLine];
        if (!data) break;

        if ([_delegate respondsToSelector:@selector(ircConnectionDidReceive:)]) {
            [_delegate ircConnectionDidReceive:data];
        }
    }
}

- (void)tcpClientDidSendData:(TCPClient*)sender
{
    _sending = NO;
    [self tryToSend];
}

@end
