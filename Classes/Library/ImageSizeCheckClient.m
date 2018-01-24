// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "ImageSizeCheckClient.h"


#define IMAGE_SIZE_CHECK_TIMEOUT    30


@implementation ImageSizeCheckClient
{
    NSURLSession *_session;
    NSURLSessionTask *_task;
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
    [_task cancel];
    _task = nil;
    _response = nil;
}

- (void)checkSize
{
    [self cancel];

    if (!_session) {
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration]];
    }

    NSURL *url = [NSURL URLWithString:_url];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:IMAGE_SIZE_CHECK_TIMEOUT];
    [request setHTTPMethod:@"HEAD"];

    if ([url.host hasSuffix:@"pixiv.net"]) {
        [request setValue:@"http://www.pixiv.net" forHTTPHeaderField:@"Referer"];
    }

    __weak typeof(self) weakSelf = self;
    _task = [_session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(self) strongSelf = weakSelf;
            if (strongSelf) {
                if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                    [strongSelf handleResponse:(NSHTTPURLResponse *)response error:error];
                } else {
                    [strongSelf handleResponse:nil error:error];
                }
            }
        });
    }];
    [_task resume];
}

- (void)handleResponse:(NSHTTPURLResponse *)response error:(NSError *)error
{
    _response = response;

    NSString *contentType;
    long long contentLength = 0;
    int statusCode = _response.statusCode;

    if (200 <= statusCode && statusCode < 300) {
        NSDictionary *header = _response.allHeaderFields;
        NSNumber *contentLengthNumber = [header objectForKey:@"Content-Length"];
        if ([contentLengthNumber respondsToSelector:@selector(longLongValue)]) {
            contentLength = contentLengthNumber.longLongValue;
        }
        contentType = [header objectForKey:@"Content-Type"];
    }

    if (contentLength) {
        if ([_delegate respondsToSelector:@selector(imageSizeCheckClient:didReceiveContentLength:andType:)]) {
            [_delegate imageSizeCheckClient:self didReceiveContentLength:contentLength andType:contentType];
        }
    } else {
        if ([_delegate respondsToSelector:@selector(imageSizeCheckClient:didFailWithError:statusCode:)]) {
            [_delegate imageSizeCheckClient:self didFailWithError:nil statusCode:statusCode];
        }
    }
}

@end
