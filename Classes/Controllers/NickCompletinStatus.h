// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

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
