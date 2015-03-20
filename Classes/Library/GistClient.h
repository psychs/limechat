// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSInteger, GistClientStage) {
    kGistClientGetTop,
    kGistClientPost,
} ;


@interface GistClient : NSObject

@property (nonatomic, weak) id delegate;

- (void)cancel;
- (void)send:(NSString*)text fileType:(NSString*)fileType private:(BOOL)isPrivate;

@end


@interface NSObject (GistClientDelegate)
- (void)gistClient:(GistClient*)sender didReceiveResponse:(NSString*)url;
- (void)gistClient:(GistClient*)sender didFailWithError:(NSString*)error statusCode:(int)statusCode;
@end
