// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import <Foundation/Foundation.h>


@interface CustomJSFile : NSObject
{
	NSString* fileName;
	NSString* content;
}

@property (nonatomic, retain) NSString* fileName;
@property (nonatomic, readonly) NSString* content;

- (void)reload;

@end
