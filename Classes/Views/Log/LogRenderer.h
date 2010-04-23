// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the new BSD license.

#import <Cocoa/Cocoa.h>


NSString* logEscape(NSString* s);


@interface LogRenderer : NSObject

+ (void)setUp;
+ (NSString*)renderBody:(NSString*)body keywords:(NSArray*)keywords excludeWords:(NSArray*)excludeWords highlightWholeLine:(BOOL)highlightWholeLine exactWordMatch:(BOOL)exactWordMatch highlighted:(BOOL*)highlighted;

@end
