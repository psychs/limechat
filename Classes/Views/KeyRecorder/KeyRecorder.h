// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Cocoa/Cocoa.h>
#import "KeyRecorderCell.h"


@interface KeyRecorder : NSControl

@property (nonatomic, weak) IBOutlet id delegate;
@property (nonatomic) int keyCode;
@property (nonatomic) NSUInteger modifierFlags;
@property (nonatomic, readonly) BOOL valid;

@end


@interface NSObject (KeyRecorder)
- (void)keyRecorderDidChangeKey:(KeyRecorder*)sender;
@end
