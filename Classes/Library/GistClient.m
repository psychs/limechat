// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "GistClient.h"
#import "GTMNSString+URLArguments.h"

@import Foundation;


#define GIST_TOP_URL    @"https://api.github.com/"
#define GIST_POST_URL   @"https://api.github.com/gists"
#define TIMEOUT         10


@implementation GistClient
{
    GistClientStage _stage;
    NSString* _text;
    NSString* _fileType;
    BOOL _isPrivate;

    NSURLConnection* _conn;
    NSMutableData* _buf;
    NSString* _destUrl;
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

    _buf = [NSMutableData new];
}

- (NSString*)formatParameters:(NSDictionary*)params
{
    if (!params) return @"";

    NSMutableArray* ary = [NSMutableArray array];
    for (NSString* key in params) {
        [ary addObject:[NSString stringWithFormat:@"%@=%@", key, [[params objectForKey:key] gtm_stringByEscapingForURLArgument]]];
    }
    return [ary componentsJoinedByString:@"&"];
}

- (void)send:(NSString*)aText fileType:(NSString*)aFileType private:(BOOL)aIsPrivate
{
    [self cancel];
    _destUrl = nil;
    _stage = kGistClientGetTop;

    _text = aText;
    _fileType = aFileType;
    _isPrivate = aIsPrivate;

    NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:GIST_TOP_URL] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:TIMEOUT];
    _conn = [[NSURLConnection alloc] initWithRequest:req delegate:self];
}

- (void) postPublicGist
{
    [self cancel];
    _stage = kGistClientPost;

    NSMutableDictionary* gist = [NSMutableDictionary dictionary];
    [gist setObject:_text forKey:@"content"];

    NSMutableDictionary* files = [NSMutableDictionary dictionaryWithObjectsAndKeys:gist,[@"limechat_gist." stringByAppendingString:_fileType], nil];
    NSMutableDictionary* postData = [NSMutableDictionary dictionaryWithObjectsAndKeys:files,@"files", nil];
    NSString *isPublic = (_isPrivate) ? @"false" : @"true";
    [postData setObject:isPublic forKey:@"public"];

    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:postData options:0 error:&error];

    if (!data) {
        NSLog(@"%@", error);
    } else {
        NSString *JSONString = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding];
        NSLog(@"%@", JSONString);
    }

    NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:GIST_POST_URL] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:TIMEOUT];
    [req setHTTPMethod:@"POST"];
    [req setValue:@"application/json" forHTTPHeaderField:@"Content-type"];
    [req setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [req setHTTPBody:data];

    _conn = [[NSURLConnection alloc] initWithRequest:req delegate:self];
}

#pragma mark - NSURLConnection Delegate

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    return nil;
}

- (void)connection:(NSURLConnection *)sender didReceiveData:(NSData *)data
{
    if (_conn != sender) return;

    [_buf appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)sender
{
    if (_conn != sender) return;

    if (_stage == kGistClientGetTop) {
        [_buf setLength:0];
        [self postPublicGist];
    }
    else {
        if ([_delegate respondsToSelector:@selector(gistClient:didReceiveResponse:)]) {

            NSError* error;
            NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:_buf options:0 error:&error];

            if (!dictionary) {
                NSLog(@"Error serializing JSON: %@", error);
                [_delegate gistClient:self didReceiveResponse:nil];
            } else {
                _destUrl = [dictionary valueForKey:@"html_url"];
                [_buf setLength:0];
                [_delegate gistClient:self didReceiveResponse:_destUrl];
            }
        }
    }
}

- (void)connection:(NSURLConnection*)sender didFailWithError:(NSError*)error
{
    if (_conn != sender) return;

    [self cancel];

    if ([_delegate respondsToSelector:@selector(gistClient:didFailWithError:statusCode:)]) {
        [_delegate gistClient:self didFailWithError:[error localizedDescription] statusCode:0];
    }
}

- (NSURLRequest *)connection:(NSURLConnection *)sender willSendRequest:(NSURLRequest *)req redirectResponse:(NSHTTPURLResponse *)res
{
    if (_conn != sender) return req;

    if (_stage == kGistClientPost) {
        if (res && res.statusCode == 302) {
            _destUrl = req.URL.absoluteString;

            // Do not cancel request here.
            // It causes memory leak in NSURLConnection.
        }
    }

    return req;
}

@end
