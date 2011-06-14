// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "ImageDownloadManager.h"
#import "ImageSizeCheckClient.h"
#import "IRCWorld.h"


static ImageDownloadManager* instance;


@implementation ImageDownloadManager

@synthesize world;

- (id)init
{
	self = [super init];
	if (self) {
		checkers = [NSMutableSet new];
	}
	return self;
}

- (void)dealloc
{
	[checkers makeObjectsPerformSelector:@selector(cancel)];
	[checkers release];
	[super dealloc];
}

+ (ImageDownloadManager*)instance
{
	if (!instance) {
		instance = [ImageDownloadManager new];
	}
	return instance;
}

+ (void)disposeInstance
{
	[instance release];
	instance = nil;
}

- (void)checkImageSize:(NSString*)url client:(IRCClient*)client channel:(IRCChannel*)channel lineNumber:(int)lineNumber imageIndex:(int)imageIndex
{
	ImageSizeCheckClient* c = [[ImageSizeCheckClient new] autorelease];
	c.delegate = self;
	c.url = url;
	c.uid = client.uid;
	c.cid = channel.uid;
	c.lineNumber = lineNumber;
	c.imageIndex = imageIndex;
	[c checkSize];
	[checkers addObject:c];
}

#pragma mark -
#pragma mark ImageSizeCheckClient Delegate

- (void)imageSizeCheckClient:(ImageSizeCheckClient*)sender didReceiveContentLength:(long long)contentLength
{
	[[sender retain] autorelease];
	[checkers removeObject:sender];
	
	int uid = sender.uid;
	int cid = sender.cid;
	LogController* log = nil;
	
	if (cid) {
		IRCChannel* channel = [world findChannelByClientId:uid channelId:cid];
		if (channel) {
			log = channel.log;
		}
	}
	else {
		IRCClient* client = [world findClientById:uid];
		if (client) {
			log = client.log;
		}
	}
	
	if (log) {
		[log expandImage:sender.url lineNumber:sender.lineNumber imageIndex:sender.imageIndex contentLength:contentLength];
	}
}

- (void)imageSizeCheckClient:(ImageSizeCheckClient*)sender didFailWithError:(NSError*)error statusCode:(int)statusCode
{
	[[sender retain] autorelease];
	[checkers removeObject:sender];
}

@end
