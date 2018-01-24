// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Cocoa/Cocoa.h>

@protocol HostResolverDelegate;

@interface HostResolver : NSObject

@property (nonatomic, weak) id<HostResolverDelegate> delegate;

- (instancetype)initWithDelegate:(id<HostResolverDelegate>)delegate;
- (void)resolve:(NSString *)hostname;

@end


@protocol HostResolverDelegate <NSObject>
@optional
- (void)hostResolver:(HostResolver *)sender didResolve:(NSHost *)host;
- (void)hostResolver:(HostResolver *)sender didNotResolve:(NSString *)hostname;
@end
