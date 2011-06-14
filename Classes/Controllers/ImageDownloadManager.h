// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Cocoa/Cocoa.h>
#import "IRCClient.h"
#import "IRCChannel.h"


@interface ImageDownloadManager : NSObject
{
	IRCWorld* world;
	NSMutableSet* checkers;
}

@property (nonatomic, assign) IRCWorld* world;

+ (ImageDownloadManager*)instance;
+ (void)disposeInstance;

- (void)checkImageSize:(NSString*)url client:(IRCClient*)client channel:(IRCChannel*)channel lineNumber:(int)lineNumber imageIndex:(int)imageIndex;

@end
