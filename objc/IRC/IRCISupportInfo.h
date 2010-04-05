// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import <Foundation/Foundation.h>


#define MODES_SIZE	52


@interface IRCISupportInfo : NSObject
{
	unsigned char modes[MODES_SIZE];
	int nickLen;
	int modesCount;
}

@property (nonatomic, readonly) int nickLen;
@property (nonatomic, readonly) int modesCount;

- (void)reset;
- (void)update:(NSString*)s;
- (NSArray*)parseMode:(NSString*)s;

@end


@interface IRCModeInfo : NSObject
{
	unsigned char mode;
	BOOL plus;
	BOOL op;
	BOOL simpleMode;
	NSString* param;
}

@property (nonatomic, assign) unsigned char mode;
@property (nonatomic, assign) BOOL plus;
@property (nonatomic, assign) BOOL op;
@property (nonatomic, assign) BOOL simpleMode;
@property (nonatomic, retain) NSString* param;

+ (IRCModeInfo*)modeInfo;

@end
