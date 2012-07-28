// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Foundation/Foundation.h>


#define TwitterAvatarURLManagerDidGetImageURLNotification   @"TwitterAvatarURLManagerDidGetImageURLNotification"


@interface TwitterAvatarURLManager : NSObject

+ (TwitterAvatarURLManager*)instance;

- (NSString*)imageURLForTwitterScreenName:(NSString*)screenName;
- (BOOL)fetchImageURLForTwitterScreenName:(NSString*)screenName;

@end
