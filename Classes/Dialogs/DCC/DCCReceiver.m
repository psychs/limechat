// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "DCCReceiver.h"


#define DOWNLOADING_PREFIX  @"__download__"
#define RECORDS_LEN         10


@implementation DCCReceiver
{
    TCPClient* _sock;
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
    [_sock close];
}

- (void)setPath:(NSString *)value
{
    if (_path != value) {
        _path = [value stringByExpandingTildeInPath];
    }
}

- (void)setFileName:(NSString *)value
{
    if (_fileName != value) {
        _fileName = value;
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

- (void)open
{
    if (_sock) {
        [self close];
    }

    _currentRecord = 0;
    [_speedRecords removeAllObjects];

    _sock = [TCPClient new];
    _sock.delegate = self;
    _sock.host = _host;
    _sock.port = _port;
    [_sock open];
}

- (void)close
{
    [_sock close];
    _sock = nil;

    [self closeFile];

    if (_status != DCC_ERROR && _status != DCC_COMPLETE) {
        _status = DCC_STOP;
    }

    [_delegate dccReceiveOnClose:self];
}

- (void)onTimer
{
    if (_status != DCC_RECEIVING) return;

    [_speedRecords addObject:@(_currentRecord)];
    if (_speedRecords.count > RECORDS_LEN) [_speedRecords removeObjectAtIndex:0];
    _currentRecord = 0;
}

- (void)openFile
{
    if (_file) return;

    NSString* base = [_fileName stringByDeletingPathExtension];
    NSString* ext = [_fileName pathExtension];

    NSFileManager* fm = [NSFileManager defaultManager];
    NSString* fullName = [_path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@%@", DOWNLOADING_PREFIX, _fileName]];

    int i = 0;
    while ([fm fileExistsAtPath:fullName]) {
        fullName = [_path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@%@_%d.%@", DOWNLOADING_PREFIX, base, i, ext]];
        ++i;
    }

    NSString* dir = [fullName stringByDeletingLastPathComponent];
    [fm createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:NULL];
    [fm createFileAtPath:fullName contents:[NSData data] attributes:nil];

    _file = [NSFileHandle fileHandleForUpdatingAtPath:fullName];
    _downloadFileName = fullName;
}

- (void)closeFile
{
    if (!_file) return;

    [_file closeFile];
    _file = nil;

    if (_status == DCC_COMPLETE) {
        NSString* base = [_fileName stringByDeletingPathExtension];
        NSString* ext = [_fileName pathExtension];
        NSString* fullName = [_path stringByAppendingPathComponent:_fileName];

        NSFileManager* fm = [NSFileManager defaultManager];

        int i = 0;
        while ([fm fileExistsAtPath:fullName]) {
            fullName = [_path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_%d.%@", base, i, ext]];
            ++i;
        }

        [fm moveItemAtPath:_downloadFileName toPath:fullName error:NULL];
        _downloadFileName = fullName;
    }
}

#pragma mark - TCPClient Delegate

- (void)tcpClientDidConnect:(TCPClient*)sender
{
    _processedSize = 0;
    _status = DCC_RECEIVING;

    [self openFile];

    [_delegate dccReceiveOnOpen:self];
}

- (void)tcpClientDidDisconnect:(TCPClient*)sender
{
    if (_status == DCC_COMPLETE || _status == DCC_ERROR) return;

    _status = DCC_ERROR;
    _error = @"Disconnected";
    [self close];

    [_delegate dccReceiveOnError:self];
}

- (void)tcpClient:(TCPClient*)sender error:(NSString*)err
{
    if (_status == DCC_COMPLETE || _status == DCC_ERROR) return;

    _status = DCC_ERROR;
    _error = err;
    [self close];

    [_delegate dccReceiveOnError:self];
}

- (void)tcpClientDidReceiveData:(TCPClient*)sender
{
    NSData* data = [_sock read];
    _processedSize += data.length;
    _currentRecord += data.length;

    if (data.length) {
        [_file writeData:data];
    }

    uint32_t rsize = _processedSize & 0xFFFFFFFF;
    unsigned char ack[4];
    ack[0] = (rsize >> 24) & 0xFF;
    ack[1] = (rsize >> 16) & 0xFF;
    ack[2] = (rsize >>  8) & 0xFF;
    ack[3] = rsize & 0xFF;
    [_sock write:[NSData dataWithBytes:ack length:4]];

    _progressBar.doubleValue = _processedSize;
    [_progressBar setNeedsDisplay:YES];

    if (_processedSize >= _size) {
        _status = DCC_COMPLETE;
        [self close];
        [_delegate dccReceiveOnComplete:self];
    }
}

- (void)tcpClientDidSendData:(TCPClient*)sender
{
}

@end
