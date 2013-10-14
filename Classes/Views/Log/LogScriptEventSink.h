// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Cocoa/Cocoa.h>


@class LogController;
@class LogPolicy;


@interface LogScriptEventSink : NSObject

@property (nonatomic, weak) id owner;
@property (nonatomic) LogPolicy* policy;

@end
