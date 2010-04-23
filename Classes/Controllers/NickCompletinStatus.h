// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the new BSD license.

#import <Foundation/Foundation.h>


@interface NickCompletinStatus : NSObject
{
	NSString* text;
	NSRange range;
}

@property (nonatomic, retain) NSString* text;
@property (nonatomic, assign) NSRange range;

- (void)clear;

@end
