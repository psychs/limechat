// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Foundation/Foundation.h>
#import "IRCClient.h"
#import "ImageSizeCheckClient.h"

@interface PixivSchemaManager : NSObject
{
    NSMutableSet* clients;
    __weak IRCWorld *world;
}

@property (nonatomic, weak) IRCWorld* world;

+ (PixivSchemaManager*)instance;
+ (void)disposeInstance;

- (void)beginGetImageURL:(NSString *)illustId forClient:(ImageSizeCheckClient *)client;

@end

@interface NSObject (PixivSchemaManagerDelegate)
- (void)pixivImageURLObtained:(NSURL *)url;
- (void)pixivImageURLFailed:(NSError *)error;
@end
