// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import <Foundation/Foundation.h>


@interface GistClient : NSObject
{
	id delegate;
	NSURLConnection* conn;
}

@property (nonatomic, assign) id delegate;

- (void)cancel;
- (void)send:(NSString*)text fileType:(NSString*)fileType private:(BOOL)private;

@end


@interface NSObject (GistClientDelegate)
- (void)gistClient:(GistClient*)sender didReceiveResponse:(NSString*)url;
- (void)gistClient:(GistClient*)sender didFailWithError:(NSString*)error statusCode:(int)statusCode;
@end
