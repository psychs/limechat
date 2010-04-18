// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import <Cocoa/Cocoa.h>


@interface URLOpener : NSObject

+ (void)open:(NSURL*)url;
+ (void)openAndActivate:(NSURL*)url;

@end
