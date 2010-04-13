// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import <Foundation/Foundation.h>


@interface NSData (Kana)

- (NSData*)convertKanaFromISO2022ToNative;
- (NSData*)convertKanaFromNativeToISO2022;

@end
