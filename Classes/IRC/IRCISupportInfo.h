// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Foundation/Foundation.h>


#define MODES_SIZE	52


@interface IRCISupportInfo : NSObject
{
	NSMutableDictionary *prefixesMap;
	unsigned char modes[MODES_SIZE];
	int nickLen;
	int modesCount;
}

@property (nonatomic, readonly) int nickLen;
@property (nonatomic, readonly) int modesCount;
@property (nonatomic, readonly) NSMutableDictionary *prefixesMap;

- (void)reset;
- (void)update:(NSString*)s;
- (NSArray*)parseMode:(NSString*)s;
- (UniChar)userModeByPrefix:(NSString*)p;

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
