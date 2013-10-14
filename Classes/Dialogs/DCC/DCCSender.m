// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "DCCSender.h"
#import "Preferences.h"


#define RECORDS_LEN     10
#define MAX_QUEUE_SIZE  2
#define BUF_SIZE        (1024 * 64)
#define RATE_LIMIT      (1024 * 1024 * 5)


@implementation DCCSender
{
    TCPServer* _sock;
    TCPClient* _client;
    NSFileHandle* _file;
    NSMutableArray* _speedRecords;
    double _currentRecord;
}

- (id)init
{
    self = [super init];
    if (self) {
        _speedRecords = [NSMutableArray new];
    }
    return self;
}

- (void)dealloc
{
    [_client close];
    [_sock closeAllClients];
    [_sock close];
    [_file closeFile];
}

- (void)setFullFileName:(NSString *)value
{
    if (_fullFileName != value) {
        _fullFileName = value;

        NSFileManager* fm = [NSFileManager defaultManager];
        NSDictionary* attr = [fm attributesOfItemAtPath:_fullFileName error:NULL];
        if (attr) {
            NSNumber* sizeNum = [attr objectForKey:NSFileSize];
            _size = [sizeNum longLongValue];
        }
        else {
            _size = 0;
        }

        _fileName = [_fullFileName lastPathComponent];
        _icon = [[NSWorkspace sharedWorkspace] iconForFileType:[_fileName pathExtension]];
    }
}

- (double)speed
{
    if (!_speedRecords.count) return 0;

    double sum = 0;
    for (NSNumber* num in _speedRecords) {
        sum += [num doubleValue];
    }
    return sum / _speedRecords.count;
}

- (BOOL)open
{
    _port = [Preferences dccFirstPort];

    while (![self doOpen]) {
        ++_port;
        if ([Preferences dccLastPort] < _port) {
            _status = DCC_ERROR;
            _error = @"No available ports";

            [_delegate dccSenderOnError:self];
            return NO;
        }
    }

    return YES;
}

- (void)close
{
    if (_sock) {
        [_client close];
        _client = nil;

        [_sock closeAllClients];
        [_sock close];
        _sock = nil;
    }

    [self closeFile];

    if (_status != DCC_ERROR && _status != DCC_COMPLETE) {
        _status = DCC_STOP;
    }

    [_delegate dccSenderOnClose:self];
}

- (void)onTimer
{
    if (_status != DCC_SENDING) return;

    [_speedRecords addObject:@(_currentRecord)];
    if (_speedRecords.count > RECORDS_LEN) [_speedRecords removeObjectAtIndex:0];
    _currentRecord = 0;

    [self send];
}

- (void)setAddressError
{
    _status = DCC_ERROR;
    _error = @"Cannot detect your IP address";
    [_delegate dccSenderOnError:self];
}

- (BOOL)doOpen
{
    if (_sock) {
        [self close];
    }

    _status = DCC_INIT;
    _processedSize = 0;
    _currentRecord = 0;
    [_speedRecords removeAllObjects];

    _sock = [TCPServer new];
    _sock.delegate = self;
    _sock.port = _port;
    BOOL res = [_sock open];
    if (!res) return NO;

    _status = DCC_LISTENING;
    [self openFile];
    if (!_file) return NO;

    [_delegate dccSenderOnListen:self];
    return YES;
}

- (void)openFile
{
    if (_file) {
        [self closeFile];
    }

    _file = [NSFileHandle fileHandleForReadingAtPath:_fullFileName];
    if (!_file) {
        _status = DCC_ERROR;
        _error = @"Could not open file";
        [self close];
        [_delegate dccSenderOnError:self];
    }
}

- (void)closeFile
{
    if (!_file) return;

    [_file closeFile];
    _file = nil;
}

- (void)send
{
    if (_status == DCC_COMPLETE) return;
    if (_processedSize >= _size) return;
    if (!_client) return;

    while (1) {
        if (_currentRecord >= RATE_LIMIT) return;
        if (_client.sendQueueSize >= MAX_QUEUE_SIZE) return;
        if (_processedSize >= _size) {
            [self closeFile];
            return;
        }

        NSData* data = [_file readDataOfLength:BUF_SIZE];
        _processedSize += data.length;
        _currentRecord += data.length;
        [_client write:data];

        [_progressBar setDoubleValue:_processedSize];
        [_progressBar setNeedsDisplay:YES];
    }
}

#pragma mark - TCPServer Delegate

- (void)tcpServer:(TCPServer*)sender didAccept:(TCPClient*)aClient
{
}

- (void)tcpServer:(TCPServer*)sender didConnect:(TCPClient*)aClient
{
    if (_sock) {
        [_sock close];
    }

    _client = aClient;
    _status = DCC_SENDING;
    [_delegate dccSenderOnConnect:self];

    [self send];
}

- (void)tcpServer:(TCPServer*)sender client:(TCPClient*)aClient error:(NSString*)err
{
    if (_status == DCC_COMPLETE || _status == DCC_ERROR) return;

    _status = DCC_ERROR;
    _error = err;
    [self close];
    [_delegate dccSenderOnError:self];
}

- (void)tcpServer:(TCPServer*)sender didDisconnect:(TCPClient*)aClient
{
    if (_processedSize >= _size) {
        _status = DCC_COMPLETE;
        [self close];
        return;
    }

    if (_status == DCC_COMPLETE || _status == DCC_ERROR) return;

    _status = DCC_ERROR;
    _error = @"Disconnected";
    [self close];
    [_delegate dccSenderOnError:self];
}

- (void)tcpServer:(TCPServer*)sender didReceiveData:(TCPClient*)aClient
{
    [aClient read];
}

- (void)tcpServer:(TCPServer*)sender didSendData:(TCPClient*)aClient
{
    if (_processedSize >= _size) {
        if (!_client.sendQueueSize) {
            _status = DCC_COMPLETE;
            [_delegate dccSenderOnComplete:self];
        }
    }
    else {
        [self send];
    }
}

@end
