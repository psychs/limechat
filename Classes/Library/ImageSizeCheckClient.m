// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "ImageSizeCheckClient.h"


#define IMAGE_SIZE_CHECK_TIMEOUT    30


@implementation ImageSizeCheckClient

@synthesize delegate;
@synthesize url;
@synthesize uid;
@synthesize cid;
@synthesize lineNumber;
@synthesize imageIndex;

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
    [url release];
    [super dealloc];
}

- (void)cancel
{
    [conn cancel];
    [conn release];
    conn = nil;

    [response release];
    response = nil;
}

- (void)checkSize
{
    [self cancel];

    NSURL* u = [NSURL URLWithString:url];
    NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:u cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:IMAGE_SIZE_CHECK_TIMEOUT];
    [req setHTTPMethod:@"HEAD"];

    if ([[u host] hasSuffix:@"pixiv.net"]) {
        [req setValue:@"http://www.pixiv.net" forHTTPHeaderField:@"Referer"];
    }

    conn = [[NSURLConnection alloc] initWithRequest:req delegate:self];
}

#pragma mark -
#pragma mark NSURLConnection Delegate

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    return nil;
}

- (void)connection:(NSURLConnection *)sender didReceiveResponse:(NSHTTPURLResponse *)aResponse
{
    if (conn != sender) return;

    [response autorelease];
    response = [aResponse retain];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)sender
{
    if (conn != sender) return;

    long long contentLength = 0;
    NSString* contentType;
    int statusCode = [response statusCode];

    if (200 <= statusCode && statusCode < 300) {
        NSDictionary* header = [response allHeaderFields];
        NSNumber* contentLengthNum = [header objectForKey:@"Content-Length"];
        if ([contentLengthNum respondsToSelector:@selector(longLongValue)]) {
            contentLength = [contentLengthNum longLongValue];
        }
        contentType = [header objectForKey:@"Content-Type"];
    }

    if (contentLength) {
        if ([delegate respondsToSelector:@selector(imageSizeCheckClient:didReceiveContentLength:andType:)]) {
            [delegate imageSizeCheckClient:self didReceiveContentLength:contentLength andType:contentType];
        }
    }
    else {
        if ([delegate respondsToSelector:@selector(imageSizeCheckClient:didFailWithError:statusCode:)]) {
            [delegate imageSizeCheckClient:self didFailWithError:nil statusCode:statusCode];
        }
    }
}

- (void)connection:(NSURLConnection*)sender didFailWithError:(NSError*)error
{
    if (conn != sender) return;

    [self cancel];

    if ([delegate respondsToSelector:@selector(imageSizeCheckClient:didFailWithError:statusCode:)]) {
        [delegate imageSizeCheckClient:self didFailWithError:error statusCode:0];
    }
}

@end
