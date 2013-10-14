// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "TwitterAvatarURLManager.h"
#import "TwitterImageURLClient.h"


@implementation TwitterAvatarURLManager
{
    NSMutableDictionary* _connections;
    NSMutableDictionary* _imageUrls;
}

- (id)init
{
    self = [super init];
    if (self) {
        _connections = [NSMutableDictionary new];
        _imageUrls = [NSMutableDictionary new];
    }
    return self;
}

+ (TwitterAvatarURLManager*)instance
{
    static TwitterAvatarURLManager *instance = nil;
    if (!instance) {
        instance = [self new];
    }
    return instance;
}

- (void)dealloc
{
    for (TwitterImageURLClient* c in _connections) {
        [c cancel];
    }
}

- (NSString*)imageURLForTwitterScreenName:(NSString*)screenName
{
    return [_imageUrls objectForKey:screenName];
}

- (BOOL)fetchImageURLForTwitterScreenName:(NSString*)screenName
{
    if (!screenName.length) {
        return NO;
    }

    NSString* url = [_imageUrls objectForKey:screenName];
    if (url) {
        return NO;
    }

    if ([_connections objectForKey:screenName]) {
        return NO;
    }

    TwitterImageURLClient *client = [TwitterImageURLClient new];
    client.delegate = self;
    client.screenName = screenName;
    [_connections setObject:client forKey:screenName];
    [client getImageURL];

    return YES;
}


#pragma mark - TwitterImageURLClientDelegate

- (void)twitterImageURLClient:(TwitterImageURLClient*)sender didGetImageURL:(NSString*)imageUrl
{
    [_connections removeObjectForKey:sender];

    NSString* screenName = sender.screenName;
    if (screenName.length && imageUrl.length) {
        [_imageUrls setObject:imageUrl forKey:screenName];
        [[NSNotificationCenter defaultCenter] postNotificationName:TwitterAvatarURLManagerDidGetImageURLNotification object:screenName];
    }
}

- (void)twitterImageURLClientDidReceiveBadURL:(TwitterImageURLClient*)sender
{
    [_connections removeObjectForKey:sender];
}

- (void)twitterImageURLClient:(TwitterImageURLClient*)sender didFailWithError:(NSString*)error
{
    [_connections removeObjectForKey:sender];
}

@end
