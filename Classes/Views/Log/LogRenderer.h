// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Cocoa/Cocoa.h>


NSString* logEscape(NSString* s);
NSString* tagEscape(NSString* s);


@interface LogRenderer : NSObject

+ (void)setUp;
+ (NSString*)renderBody:(NSString*)body keywords:(NSArray*)keywords excludeWords:(NSArray*)excludeWords highlightWholeLine:(BOOL)highlightWholeLine exactWordMatch:(BOOL)exactWordMatch highlighted:(BOOL*)highlighted URLRanges:(NSArray**)urlRanges;

@end
