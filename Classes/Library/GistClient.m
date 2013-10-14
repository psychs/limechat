// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "GistClient.h"
#import "GTMNSString+URLArguments.h"


#define GIST_TOP_URL    @"https://gist.github.com/"
#define GIST_POST_URL   @"https://gist.github.com/gists"
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

- (void)postDataWithAutheToken:(NSString*)authToken
{
    [self cancel];
    _stage = kGistClientPost;

    NSMutableDictionary* params = [NSMutableDictionary dictionary];
    [params setObject:@"" forKey:@"gist[description]"];
    [params setObject:@"" forKey:@"gist[files][][oid]"];
    [params setObject:@"" forKey:@"gist[files][][name]"];
    [params setObject:_text forKey:@"gist[files][][content]"];
    [params setObject:_fileType forKey:@"gist[files][][language]"];
    if (_isPrivate) {
        [params setObject:@"0" forKey:@"gist[public]"];
    }
    if (authToken) {
        [params setObject:authToken forKey:@"authenticity_token"];
    }

    NSData* body = [[self formatParameters:params] dataUsingEncoding:NSUTF8StringEncoding];

    NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:GIST_POST_URL] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:TIMEOUT];
    [req setHTTPMethod:@"POST"];
    [req setHTTPBody:body];

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
        NSString* s = [[NSString alloc] initWithData:_buf encoding:NSUTF8StringEncoding];
        NSString* authToken = nil;

        NSRange authInputTagRange = [s rangeOfString:@"<input name=\"authenticity_token\""];
        if (authInputTagRange.location != NSNotFound) {
            int start = NSMaxRange(authInputTagRange);
            NSRange tokenStartRange = [s rangeOfString:@"value=\"" options:0 range:NSMakeRange(start, s.length - start)];
            if (tokenStartRange.location != NSNotFound) {
                start = NSMaxRange(tokenStartRange);
                NSRange tokenEndRange = [s rangeOfString:@"\"" options:0 range:NSMakeRange(start, s.length - start)];
                if (tokenEndRange.location != NSNotFound) {
                    start = NSMaxRange(tokenStartRange);
                    int end = tokenEndRange.location;
                    authToken = [s substringWithRange:NSMakeRange(start, end - start)];
                }
            }
        }

        if (!authToken) {
            NSRange csrfTokenRange = [s rangeOfString:@"\"csrf-token"];
            if (csrfTokenRange.location != NSNotFound) {
                NSRange tokenEndRange = [s rangeOfString:@"\"" options:NSBackwardsSearch range:NSMakeRange(0, csrfTokenRange.location)];
                if (tokenEndRange.location != NSNotFound) {
                    NSRange tokenStartRange = [s rangeOfString:@"\"" options:NSBackwardsSearch range:NSMakeRange(0, tokenEndRange.location)];
                    if (tokenStartRange.location != NSNotFound) {
                        int start = tokenStartRange.location + 1;
                        int end = tokenEndRange.location;
                        authToken = [s substringWithRange:NSMakeRange(start, end - start)];
                    }
                }
            }
        }

        if (authToken) {
            [self postDataWithAutheToken:authToken];
        }
        else {
            if ([_delegate respondsToSelector:@selector(gistClient:didFailWithError:statusCode:)]) {
                [_delegate gistClient:self didFailWithError:@"Failed to post to Gist" statusCode:0];
            }
        }
    }
    else {
        if ([_delegate respondsToSelector:@selector(gistClient:didReceiveResponse:)]) {
            [_delegate gistClient:self didReceiveResponse:_destUrl];
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
