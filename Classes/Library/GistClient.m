// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "GistClient.h"
#import "GTMNSString+URLArguments.h"


#define GIST_URL	@"http://gist.github.com/gists"
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
	[super dealloc];
}

- (void)cancel
{
	[conn cancel];
	[conn autorelease];
	conn = nil;
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

- (void)send:(NSString*)text fileType:(NSString*)fileType private:(BOOL)private
{
	[self cancel];
	
	NSMutableDictionary* params = [NSMutableDictionary dictionary];
	[params setObject:text forKey:@"file_contents[gistfile1]"];
	[params setObject:fileType forKey:@"file_ext[gistfile1]"];
	if (private) {
		[params setObject:@"on" forKey:@"private"];
	}
	
	NSData* body = [[self formatParameters:params] dataUsingEncoding:NSUTF8StringEncoding];
	
	NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:GIST_URL] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:TIMEOUT];
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

- (void)connection:(NSURLConnection*)sender didFailWithError:(NSError*)error
{
	[self cancel];
	
	if ([delegate respondsToSelector:@selector(gistClient:didFailWithError:statusCode:)]) {
		[delegate gistClient:self didFailWithError:[error localizedDescription] statusCode:0];
	}
}

- (NSURLRequest *)connection:(NSURLConnection *)sender willSendRequest:(NSURLRequest *)req redirectResponse:(NSHTTPURLResponse *)res
{
	if (res && res.statusCode == 302) {
		if ([delegate respondsToSelector:@selector(gistClient:didReceiveResponse:)]) {
			[delegate gistClient:self didReceiveResponse:req.URL.absoluteString];
		}
		return nil;
	}
	
	return req;
}

@end
