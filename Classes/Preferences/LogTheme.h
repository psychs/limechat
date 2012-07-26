// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Cocoa/Cocoa.h>


@interface LogTheme : NSObject
{
    NSString* fileName;
    NSURL* baseUrl;
    NSString* content;
}

@property (nonatomic, strong) NSString* fileName;
@property (nonatomic, readonly) NSURL* baseUrl;
@property (nonatomic, strong) NSString* content;

- (void)reload;

@end
