// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Foundation/Foundation.h>


@interface TwitterImageURLClient : NSObject
{
    __weak id delegate;
    NSString* screenName;
    
    CFReadStreamRef stream;
    CFStreamClientContext context;
    NSTimer* timeoutTimer;
}

@property (nonatomic, weak) id delegate;
@property (nonatomic, retain) NSString* screenName;

- (void)cancel;
- (void)getImageURL;

@end


@interface NSObject (TwitterImageURLClientDelegate)
- (void)twitterImageURLClient:(TwitterImageURLClient*)sender didGetImageURL:(NSString*)imageURL;
- (void)twitterImageURLClientDidReceiveBadURL:(TwitterImageURLClient*)sender;
- (void)twitterImageURLClient:(TwitterImageURLClient*)sender didFailWithError:(NSString*)error;
@end
