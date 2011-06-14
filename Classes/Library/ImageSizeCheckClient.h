// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Cocoa/Cocoa.h>
#import "IRCClient.h"
#import "IRCChannel.h"


@interface ImageSizeCheckClient : NSObject
{
	id delegate;
	NSString* url;
	int uid;
	int cid;
	int lineNumber;
	int imageIndex;
	
	NSURLConnection* conn;
	NSHTTPURLResponse* response;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, retain) NSString* url;
@property (nonatomic, assign) int uid;
@property (nonatomic, assign) int cid;
@property (nonatomic, assign) int lineNumber;
@property (nonatomic, assign) int imageIndex;

- (void)cancel;
- (void)checkSize;

@end


@interface NSObject (ImageSizeCheckClientDelegate)
- (void)imageSizeCheckClient:(ImageSizeCheckClient*)sender didReceiveContentLength:(long long)contentLength;
- (void)imageSizeCheckClient:(ImageSizeCheckClient*)sender didFailWithError:(NSError*)error statusCode:(int)statusCode;
@end
