// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import <Cocoa/Cocoa.h>


@class LogController;
@class LogPolicy;


@interface LogScriptEventSink : NSObject
{
	LogController* owner;
	LogPolicy* policy;
	
	int x;
	int y;
	CFAbsoluteTime lastClickTime;
}

@property (nonatomic, assign) id owner;
@property (nonatomic, retain) id policy;

@end
