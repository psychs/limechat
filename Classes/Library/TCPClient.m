// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "TCPClient.h"


#define LF  0xa
#define CR  0xd


@implementation TCPClient
{
    AsyncSocket* _conn;
    NSMutableData* _buffer;
    int _tag;
}

- (id)init
{
    self = [super init];
    if (self) {
        _buffer = [NSMutableData new];
    }
    return self;
}

- (id)initWithExistingConnection:(AsyncSocket*)socket
{
    self = [self init];
    if (self) {
        _conn = socket;
        _conn.delegate = self;
        [_conn setUserData:_tag];
        _active = _connecting = YES;
        _sendQueueSize = 0;
    }
    return self;
}

- (void)dealloc
{
    _conn.delegate = nil;
    [_conn disconnect];
}

- (void)open
{
    [self close];

    [_buffer setLength:0];
    ++_tag;

    _conn = [[AsyncSocket alloc] initWithDelegate:self userData:_tag];
    [_conn connectToHost:_host onPort:_port error:NULL];
    _active = _connecting = YES;
    _sendQueueSize = 0;
}

- (void)close
{
    if (!_conn) return;

    ++_tag;

    [_conn disconnect];
    _conn = nil;

    _active = _connecting = NO;
    _sendQueueSize = 0;
}

- (NSData*)read
{
    NSData* result = _buffer;
    _buffer = [NSMutableData new];
    return result;
}

- (NSData*)readLine
{
    int len = [_buffer length];
    if (!len) return nil;

    const char* bytes = [_buffer bytes];
    char* p = memchr(bytes, LF, len);
    if (!p) return nil;
    int n = p - bytes;

    if (n > 0) {
        char prev = *(p - 1);
        if (prev == CR) {
            --n;
        }
    }

    NSMutableData* result = _buffer;

    ++p;
    if (p < bytes + len) {
        _buffer = [[NSMutableData alloc] initWithBytes:p length:bytes + len - p];
    }
    else {
        _buffer = [NSMutableData new];
    }

    [result setLength:n];
    return result;
}

- (void)write:(NSData*)data
{
    if (![self connected]) return;

    ++_sendQueueSize;

    [_conn writeData:data withTimeout:-1 tag:0];
    [self waitRead];
}

- (BOOL)connected
{
    if (!_conn) return NO;
    if (![self checkTag:_conn]) return NO;
    return [_conn isConnected];
}

- (BOOL)onSocketWillConnect:(AsyncSocket*)sender
{
    if (_useSystemSocks) {
        [_conn useSystemSocksProxy];
    }
    else if (_useSocks) {
        [_conn useSocksProxyVersion:_socksVersion host:_proxyHost port:_proxyPort user:_proxyUser password:_proxyPassword];
    }

    if (_useSSL) {
        [_conn useSSL];
    }
    return YES;
}

- (void)onSocket:(AsyncSocket *)sender didConnectToHost:(NSString *)aHost port:(UInt16)aPort
{
    if (![self checkTag:sender]) return;
    [self waitRead];
    _connecting = NO;

    if ([_delegate respondsToSelector:@selector(tcpClientDidConnect:)]) {
        [_delegate tcpClientDidConnect:self];
    }
}

- (void)onSocket:(AsyncSocket*)sender willDisconnectWithError:(NSError*)error
{
    if (![self checkTag:sender]) return;
    if (!error) return;

    NSString* msg = nil;
    NSString* domain = error.domain;
    int code = error.code;

    if ([domain isEqualToString:NSPOSIXErrorDomain]) {
        msg = [AsyncSocket posixErrorStringFromErrno:[error code]];
    }
    else if ([domain isEqualToString:@"kCFStreamErrorDomainSSL"]) {
        if (-9818 <= code && code <= -9800) {
            msg = @"Connection failed: SSL problem (possibly the server doesn't support SSL or uses a bad certificate)";
        }
    }

    if (!msg) {
        msg = [error localizedDescription];
    }

    if ([_delegate respondsToSelector:@selector(tcpClient:error:)]) {
        [_delegate tcpClient:self error:msg];
    }
}

- (void)onSocketDidDisconnect:(AsyncSocket*)sender
{
    if (![self checkTag:sender]) return;

    [self close];

    if ([_delegate respondsToSelector:@selector(tcpClientDidDisconnect:)]) {
        [_delegate tcpClientDidDisconnect:self];
    }
}

- (void)onSocket:(AsyncSocket *)sender didReadData:(NSData *)data withTag:(long)aTag
{
    if (![self checkTag:sender]) return;

    [_buffer appendData:data];

    if ([_delegate respondsToSelector:@selector(tcpClientDidReceiveData:)]) {
        [_delegate tcpClientDidReceiveData:self];
    }

    [self waitRead];
}

- (void)onSocket:(AsyncSocket*)sender didWriteDataWithTag:(long)aTag
{
    if (![self checkTag:sender]) return;

    --_sendQueueSize;

    if ([_delegate respondsToSelector:@selector(tcpClientDidSendData:)]) {
        [_delegate tcpClientDidSendData:self];
    }
}

- (BOOL)checkTag:(AsyncSocket*)sock
{
    return _tag == [sock userData];
}

- (void)waitRead
{
    [_conn readDataWithTimeout:-1 tag:0];
}

@end
