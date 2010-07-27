// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

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
