// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "TCPServer.h"
#import "AsyncSocket.h"


@implementation TCPServer
{
    AsyncSocket* _conn;
    NSMutableArray *_clients;
}

- (id)init
{
    self = [super init];
    if (self) {
        _clients = [NSMutableArray new];
    }
    return self;
}

- (void)dealloc
{
    [_conn disconnect];
}

- (BOOL)open
{
    if (_conn) {
        [self close];
    }

    _conn = [[AsyncSocket alloc] initWithDelegate:self];
    _isActive = [_conn acceptOnPort:_port error:NULL];
    if (!_isActive) {
        [self close];
    }
    return _isActive;
}

- (void)close
{
    [_conn disconnect];
    _conn = nil;
    _isActive = NO;
}

- (void)closeClient:(TCPClient*)client
{
    [client close];
    [_clients removeObjectIdenticalTo:client];
}

- (void)closeAllClients
{
    for (TCPClient* c in _clients) {
        [c close];
    }
    [_clients removeAllObjects];
}

- (void)onSocket:(AsyncSocket*)sock didAcceptNewSocket:(AsyncSocket*)newSocket
{
    TCPClient* c = [[TCPClient alloc] initWithExistingConnection:newSocket];
    c.delegate = self;
    [_clients addObject:c];

    if ([_delegate respondsToSelector:@selector(tcpServer:didAccept:)]) {
        [_delegate tcpServer:self didAccept:c];
    }
}

- (void)tcpClientDidConnect:(TCPClient*)sender
{
    if ([_delegate respondsToSelector:@selector(tcpServer:didConnect:)]) {
        [_delegate tcpServer:self didConnect:sender];
    }
}

- (void)tcpClientDidDisconnect:(TCPClient*)sender
{
    if ([_delegate respondsToSelector:@selector(tcpServer:didDisconnect:)]) {
        [_delegate tcpServer:self didDisconnect:sender];
    }
    [self closeClient:sender];
}

- (void)tcpClient:(TCPClient*)sender error:(NSString*)error
{
    if ([_delegate respondsToSelector:@selector(tcpServer:client:error:)]) {
        [_delegate tcpServer:self client:sender error:error];
    }
}

- (void)tcpClientDidReceiveData:(TCPClient*)sender
{
    if ([_delegate respondsToSelector:@selector(tcpServer:didReceiveData:)]) {
        [_delegate tcpServer:self didReceiveData:sender];
    }
}

- (void)tcpClientDidSendData:(TCPClient*)sender
{
    if ([_delegate respondsToSelector:@selector(tcpServer:didSendData:)]) {
        [_delegate tcpServer:self didSendData:sender];
    }
}

@end
