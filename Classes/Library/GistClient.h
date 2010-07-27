// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

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
