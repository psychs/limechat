// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "TwitterAvatarURLManager.h"
#import "TwitterImageURLClient.h"


@implementation TwitterAvatarURLManager

- (id)init
{
    self = [super init];
    if (self) {
        connections = [NSMutableDictionary new];
        imageUrls = [NSMutableDictionary new];
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
    for (TwitterImageURLClient* c in connections) {
        [c cancel];
    }
    [connections release];
    [imageUrls release];
    [super dealloc];
}

- (NSString*)imageURLForTwitterScreenName:(NSString*)screenName
{
    return [imageUrls objectForKey:screenName];
}

- (BOOL)fetchImageURLForTwitterScreenName:(NSString*)screenName
{
    if (!screenName.length) {
        return NO;
    }
    
    NSString* url = [imageUrls objectForKey:screenName];
    if (url) {
        return NO;
    }
    
    if ([connections objectForKey:screenName]) {
        return NO;
    }
    
    TwitterImageURLClient *client = [[TwitterImageURLClient new] autorelease];
    client.delegate = self;
    client.screenName = screenName;
    [connections setObject:client forKey:screenName];
    [client getImageURL];
    
    return YES;
}


#pragma mark -
#pragma mark TwitterImageURLClientDelegate

- (void)twitterImageURLClient:(TwitterImageURLClient*)sender didGetImageURL:(NSString*)imageUrl
{
    [[sender retain] autorelease];
    [connections removeObjectForKey:sender];
    
    NSString* screenName = sender.screenName;
    if (screenName.length && imageUrl.length) {
        [imageUrls setObject:imageUrl forKey:screenName];
        [[NSNotificationCenter defaultCenter] postNotificationName:TwitterAvatarURLManagerDidGetImageURLNotification object:screenName];
    }
}

- (void)twitterImageURLClientDidReceiveBadURL:(TwitterImageURLClient*)sender
{
    [[sender retain] autorelease];
    [connections removeObjectForKey:sender];
}

- (void)twitterImageURLClient:(TwitterImageURLClient*)sender didFailWithError:(NSString*)error
{
    [[sender retain] autorelease];
    [connections removeObjectForKey:sender];
}

@end
