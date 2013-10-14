// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "ImageDownloadManager.h"
#import "ImageSizeCheckClient.h"
#import "IRCWorld.h"


static ImageDownloadManager* _instance;


@implementation ImageDownloadManager
{
    NSMutableSet* _checkers;
}

- (id)init
{
    self = [super init];
    if (self) {
        _checkers = [NSMutableSet new];
    }
    return self;
}

- (void)dealloc
{
    [_checkers makeObjectsPerformSelector:@selector(cancel)];
}

+ (ImageDownloadManager*)instance
{
    if (!_instance) {
        _instance = [ImageDownloadManager new];
    }
    return _instance;
}

+ (void)disposeInstance
{
    _instance = nil;
}

- (void)checkImageSize:(NSString*)url client:(IRCClient*)client channel:(IRCChannel*)channel lineNumber:(int)lineNumber imageIndex:(int)imageIndex
{
    ImageSizeCheckClient* c = [ImageSizeCheckClient new];
    c.delegate = self;
    c.url = url;
    c.uid = client.uid;
    c.cid = channel.uid;
    c.lineNumber = lineNumber;
    c.imageIndex = imageIndex;
    [c checkSize];
    [_checkers addObject:c];
}

#pragma mark - ImageSizeCheckClient Delegate

- (void)imageSizeCheckClient:(ImageSizeCheckClient*)sender didReceiveContentLength:(long long)contentLength andType:(NSString*)contentType
{
    [_checkers removeObject:sender];

    int uid = sender.uid;
    int cid = sender.cid;
    LogController* log = nil;

    if (cid) {
        IRCChannel* channel = [_world findChannelByClientId:uid channelId:cid];
        if (channel) {
            log = channel.log;
        }
    }
    else {
        IRCClient* client = [_world findClientById:uid];
        if (client) {
            log = client.log;
        }
    }

    if (log) {
        [log expandImage:sender.url lineNumber:sender.lineNumber imageIndex:sender.imageIndex contentLength:contentLength contentType:contentType];
    }
}

- (void)imageSizeCheckClient:(ImageSizeCheckClient*)sender didFailWithError:(NSError*)error statusCode:(int)statusCode
{
    [_checkers removeObject:sender];
}

@end
