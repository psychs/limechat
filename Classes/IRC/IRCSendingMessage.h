// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Foundation/Foundation.h>


@interface IRCSendingMessage : NSObject
{
	NSString* command;
	NSMutableArray* params;
	int penalty;
	BOOL completeColon;
	NSString* string;
}

@property (nonatomic, readonly) NSString* command;
@property (nonatomic, readonly) NSMutableArray* params;
@property (nonatomic, assign) int penalty;
@property (nonatomic, assign) BOOL completeColon;
@property (nonatomic, readonly) NSString* string;

- (id)initWithCommand:(NSString*)aCommand;
- (void)addParameter:(NSString*)parameter;

@end
