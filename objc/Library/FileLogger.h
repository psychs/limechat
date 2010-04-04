// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import <Cocoa/Cocoa.h>


@interface FileLogger : NSObject
{
	id client;
	id channel;
	
	NSString* fileName;
	NSFileHandle* file;
}

@property (nonatomic, assign) id client;
@property (nonatomic, assign) id channel;


@end
