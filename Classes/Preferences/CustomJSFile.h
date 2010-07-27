// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

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
