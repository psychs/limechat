// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "ImageSizeCheckClient.h"


#define IMAGE_SIZE_CHECK_TIMEOUT    30


@implementation ImageSizeCheckClient
{
    NSURLConnection* _conn;
    NSHTTPURLResponse* _response;
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
    [self cancel];
}

- (void)cancel
{
    [_conn cancel];
    _conn = nil;
    _response = nil;
}

- (void)checkSize
{
    [self cancel];

    NSURL* u = [NSURL URLWithString:_url];
    NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:u cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:IMAGE_SIZE_CHECK_TIMEOUT];
    [req setHTTPMethod:@"HEAD"];

    if ([[u host] hasSuffix:@"pixiv.net"]) {
        [req setValue:@"http://www.pixiv.net" forHTTPHeaderField:@"Referer"];
    }

    _conn = [[NSURLConnection alloc] initWithRequest:req delegate:self];
}

#pragma mark - NSURLConnection Delegate

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    return nil;
}

- (void)connection:(NSURLConnection *)sender didReceiveResponse:(NSHTTPURLResponse *)aResponse
{
    if (_conn != sender) return;

    _response = aResponse;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)sender
{
    if (_conn != sender) return;

    long long contentLength = 0;
    NSString* contentType;
    int statusCode = [_response statusCode];

    if (200 <= statusCode && statusCode < 300) {
        NSDictionary* header = [_response allHeaderFields];
        NSNumber* contentLengthNum = [header objectForKey:@"Content-Length"];
        if ([contentLengthNum respondsToSelector:@selector(longLongValue)]) {
            contentLength = [contentLengthNum longLongValue];
        }
        contentType = [header objectForKey:@"Content-Type"];
    }

    if (contentLength) {
        if ([_delegate respondsToSelector:@selector(imageSizeCheckClient:didReceiveContentLength:andType:)]) {
            [_delegate imageSizeCheckClient:self didReceiveContentLength:contentLength andType:contentType];
        }
    }
    else {
        if ([_delegate respondsToSelector:@selector(imageSizeCheckClient:didFailWithError:statusCode:)]) {
            [_delegate imageSizeCheckClient:self didFailWithError:nil statusCode:statusCode];
        }
    }
}

- (void)connection:(NSURLConnection*)sender didFailWithError:(NSError*)error
{
    if (_conn != sender) return;

    [self cancel];

    if ([_delegate respondsToSelector:@selector(imageSizeCheckClient:didFailWithError:statusCode:)]) {
        [_delegate imageSizeCheckClient:self didFailWithError:error statusCode:0];
    }
}

@end
