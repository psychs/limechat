// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Cocoa/Cocoa.h>


@interface HostResolver : NSObject
{
	id delegate;
}

@property (nonatomic, assign) id delegate;

- (id)initWithDelegate:(id)aDelegate;
- (void)resolve:(NSString*)hostname;

@end


@interface NSObject (HostResolverDelegate)
- (void)hostResolver:(HostResolver*)sender didResolve:(NSHost*)host;
- (void)hostResolver:(HostResolver*)sender didNotResolve:(NSString*)hostname;
@end
