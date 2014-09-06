// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "FileLogger.h"
#import "Preferences.h"
#import "IRCClient.h"
#import "IRCChannel.h"
#import "NSStringHelper.h"


@implementation FileLogger
{
    NSString* _fileName;
    NSFileHandle* _file;
}

- (id)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)dealloc
{
    [self close];
}

- (void)close
{
    if (_file) {
        [_file closeFile];
        _file = nil;
    }
}

- (void)writeLine:(NSString*)s
{
    [self open];

    if (_file) {
        s = [s stringByAppendingString:@"\n"];

        NSData* data = [s dataUsingEncoding:NSUTF8StringEncoding];
        if (!data) {
            data = [s dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
        }

        if (data) {
            [_file writeData:data];
        }
    }
}

- (void)reopenIfNeeded
{
    if (!_fileName || ![_fileName isEqualToString:[self buildFileName]]) {
        [self open];
    }
}

- (void)open
{
    [self close];

    _fileName = [self buildFileName];

    NSString* dir = [_fileName stringByDeletingLastPathComponent];

    NSFileManager* fm = [NSFileManager defaultManager];
    BOOL isDir = NO;
    if (![fm fileExistsAtPath:dir isDirectory:&isDir]) {
        [fm createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:NULL];
    }

    if (![fm fileExistsAtPath:_fileName]) {
        [fm createFileAtPath:_fileName contents:[NSData data] attributes:nil];
    }

    _file = [NSFileHandle fileHandleForUpdatingAtPath:_fileName];
    if (_file) {
        [_file seekToEndOfFile];
    }
}

- (NSString*)buildFileName
{
    NSString* base = [Preferences transcriptFolder];
    base = [base stringByExpandingTildeInPath];

    static NSDateFormatter* format = nil;
    if (!format) {
        format = [NSDateFormatter new];
        [format setDateFormat:@"yyyy-MM-dd"];
    }
    NSString* date = [format stringFromDate:[NSDate date]];
    NSString* name = [[_client name] safeFileName];
    NSString* pre = @"";
    NSString* c = @"";

    if (!_channel) {
        c = @"Console";
    }
    else if ([_channel isTalk]) {
        c = @"Talk";
        pre = [[[_channel name] safeFileName] stringByAppendingString:@"_"];
    }
    else {
        c = [[_channel name] safeFileName];
    }

    return [base stringByAppendingFormat:@"/%@/%@%@_%@.txt", c, pre, date, name];
}

@end
