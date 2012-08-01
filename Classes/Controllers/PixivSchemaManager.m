// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "PixivSchemaManager.h"
#import "PixivIllustClient.h"

static PixivSchemaManager* instance;

@implementation PixivSchemaManager

@synthesize world;

- (id)init
{
    self = [super init];
    if (self) {
        clients = [NSMutableSet new];
    }
    return self;
}

- (void)dealloc
{
    [clients makeObjectsPerformSelector:@selector(cancel)];
    [clients release];
    [super dealloc];
}

+ (PixivSchemaManager *)instance
{
    if (!instance)
        instance = [PixivSchemaManager new];
    return instance;
}

+ (void)disposeInstance
{
    [instance release];
    instance = nil;
}

- (void)beginGetImageURL:(NSString *)imageId forClient:(ImageSizeCheckClient *)client
{
    PixivIllustClient *c = [PixivIllustClient newWithIllustId:imageId];
    c.delegate = self;
    c.client = client;
    [c beginQuery];
    [clients addObject:c];
}


- (void)pixivClient:(PixivIllustClient *)sender gotPixivIllustURL:(NSURL *)url
{
    [[sender retain] autorelease];
    [clients removeObject:sender];

    if ([sender.client respondsToSelector:@selector(pixivImageURLObtained:)])
        [sender.client pixivImageURLObtained:url];
}

- (void)pixivClient:(PixivIllustClient *)sender gotError:(NSError *)error
{
    [[sender retain] autorelease];
    [clients removeObject:sender];

    if ([sender.client respondsToSelector:@selector(pixivImageURLFailed:)])
        [sender.client pixivImageURLFailed:error];
}

@end
