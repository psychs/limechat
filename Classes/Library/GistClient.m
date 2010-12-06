// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "GistClient.h"
#import "GTMNSString+URLArguments.h"


#define GIST_TOP_URL	@"https://gist.github.com/"
#define GIST_POST_URL	@"https://gist.github.com/gists"
#define TIMEOUT		10


@interface GistClient (Private)
@end


@implementation GistClient

@synthesize delegate;

- (id)init
{
	if (self = [super init]) {
	}
	return self;
}

- (void)dealloc
{
	[self cancel];
	[text release];
	[fileType release];
	[super dealloc];
}

- (void)cancel
{
	[conn cancel];
	[conn autorelease];
	conn = nil;
	
	[buf release];
	buf = [NSMutableData new];
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
	[destUrl autorelease];
	destUrl = nil;
	stage = kGistClientGetTop;
	
	[text autorelease];
	text = [aText retain];
	[aFileType autorelease];
	fileType = [aFileType retain];
	isPrivate = aIsPrivate;
	
	NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:GIST_TOP_URL] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:TIMEOUT];
	conn = [[NSURLConnection alloc] initWithRequest:req delegate:self];
}

- (void)postDataWithAutheToken:(NSString*)authToken
{
	[self cancel];
	stage = kGistClientPost;
	
	NSMutableDictionary* params = [NSMutableDictionary dictionary];
	[params setObject:@"" forKey:@"description"];
	[params setObject:@"" forKey:@"file_name[gistfile1]"];
	[params setObject:text forKey:@"file_contents[gistfile1]"];
	[params setObject:fileType forKey:@"file_ext[gistfile1]"];
	if (isPrivate) {
		[params setObject:@"private" forKey:@"action_button"];
	}
	if (authToken) {
		[params setObject:authToken forKey:@"authenticity_token"];
	}
	
	NSData* body = [[self formatParameters:params] dataUsingEncoding:NSUTF8StringEncoding];
	
	NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:GIST_POST_URL] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:TIMEOUT];
	[req setHTTPMethod:@"POST"];
	[req setHTTPBody:body];
	
	conn = [[NSURLConnection alloc] initWithRequest:req delegate:self];
}

#pragma mark -
#pragma mark NSURLConnection Delegate

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
	return nil;
}

- (void)connection:(NSURLConnection *)sender didReceiveData:(NSData *)data
{
	if (conn != sender) return;
	
	[buf appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)sender
{
	if (conn != sender) return;
	
	if (stage == kGistClientGetTop) {
		NSString* s = [[[NSString alloc] initWithData:buf encoding:NSUTF8StringEncoding] autorelease];
		NSRange start = [s rangeOfString:@"window._auth_token = \""];
		if (start.location != NSNotFound) {
			NSRange end = [s rangeOfString:@"\"" options:0 range:NSMakeRange(start.location, s.length - start.location)];
			if (end.location != NSNotFound) {
				NSString* authToken = [s substringWithRange:NSMakeRange(start.location, end.location - start.location)];
				[self postDataWithAutheToken:authToken];
			}
		}
	}
	else {
		if ([delegate respondsToSelector:@selector(gistClient:didReceiveResponse:)]) {
			[delegate gistClient:self didReceiveResponse:destUrl];
		}
	}
}

- (void)connection:(NSURLConnection*)sender didFailWithError:(NSError*)error
{
	if (conn != sender) return;
	
	[self cancel];
	
	if ([delegate respondsToSelector:@selector(gistClient:didFailWithError:statusCode:)]) {
		[delegate gistClient:self didFailWithError:[error localizedDescription] statusCode:0];
	}
}

- (NSURLRequest *)connection:(NSURLConnection *)sender willSendRequest:(NSURLRequest *)req redirectResponse:(NSHTTPURLResponse *)res
{
	if (conn != sender) return req;
	
	if (stage == kGistClientPost) {
		if (res && res.statusCode == 302) {
			[destUrl autorelease];
			destUrl = [req.URL.absoluteString retain];
			
			// Do not cancel request here.
			// It causes memory leak in NSURLConnection.
		}
	}
	
	return req;
}

@end
