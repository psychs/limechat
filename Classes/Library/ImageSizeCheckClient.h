// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Cocoa/Cocoa.h>
#import "IRCClient.h"
#import "IRCChannel.h"


@interface ImageSizeCheckClient : NSObject

@property (nonatomic, weak) id delegate;
@property (nonatomic) NSString* url;
@property (nonatomic) int uid;
@property (nonatomic) int cid;
@property (nonatomic) int lineNumber;
@property (nonatomic) int imageIndex;

- (void)cancel;
- (void)checkSize;

@end


@interface NSObject (ImageSizeCheckClientDelegate)
- (void)imageSizeCheckClient:(ImageSizeCheckClient*)sender
     didReceiveContentLength:(long long)contentLength
                     andType:(NSString*)contentType;
- (void)imageSizeCheckClient:(ImageSizeCheckClient*)sender didFailWithError:(NSError*)error statusCode:(int)statusCode;
@end
