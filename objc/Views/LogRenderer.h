#import <Cocoa/Cocoa.h>


@interface LogRenderer : NSObject

+ (NSArray*)renderBody:(NSString*)body keywords:(NSArray*)keywords excludeWords:(NSArray*)excludeWords highlightWholeLine:(BOOL)highlightWholeLine exactWordMatch:(BOOL)exactWordMatch;

@end
