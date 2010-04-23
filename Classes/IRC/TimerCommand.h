// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the new BSD license.

#import <Foundation/Foundation.h>


@interface TimerCommand : NSObject
{
	CFAbsoluteTime time;
	int cid;
	NSString* input;
}

@property (nonatomic, assign) CFAbsoluteTime time;
@property (nonatomic, assign) int cid;
@property (nonatomic, copy) NSString* input;

@end
