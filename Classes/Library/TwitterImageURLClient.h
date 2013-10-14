// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Foundation/Foundation.h>


@interface TwitterImageURLClient : NSObject

@property (nonatomic, weak) id delegate;
@property (nonatomic) NSString* screenName;

- (void)cancel;
- (void)getImageURL;

- (void)getResultCode;

@end


@interface NSObject (TwitterImageURLClientDelegate)
- (void)twitterImageURLClient:(TwitterImageURLClient*)sender didGetImageURL:(NSString*)imageURL;
- (void)twitterImageURLClientDidReceiveBadURL:(TwitterImageURLClient*)sender;
- (void)twitterImageURLClient:(TwitterImageURLClient*)sender didFailWithError:(NSString*)error;
@end
