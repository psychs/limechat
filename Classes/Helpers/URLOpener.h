// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the new BSD license.

#import <Cocoa/Cocoa.h>


@interface URLOpener : NSObject

+ (void)open:(NSURL*)url;
+ (void)openAndActivate:(NSURL*)url;

@end
