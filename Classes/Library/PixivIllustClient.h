// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "ImageSizeCheckClient.h"

@interface PixivIllustClient : NSObject
{
    WebView* webView;
    __weak id delegate;
    __weak ImageSizeCheckClient* client;
    NSString* illustId;
    NSURL *requestURL;
    bool loggingIn;
}

@property (nonatomic, weak) id delegate;
@property (nonatomic, weak) ImageSizeCheckClient* client;
@property (nonatomic, copy) NSString* illustId;

+ (PixivIllustClient *)newWithIllustId:(NSString *)illustId;

- (void)cancel;
- (void)beginQuery;

@end

@interface NSObject (PixivIllustClientDelegate)
- (void)pixivClient:(PixivIllustClient *)sender gotPixivIllustURL:(NSURL *)url;
- (void)pixivClient:(PixivIllustClient *)sender gotError:(NSError *)error;
@end
