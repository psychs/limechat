// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import <Cocoa/Cocoa.h>


@interface LogLine : NSObject
{
	NSString* time;
	NSString* place;
	NSString* nick;
	NSString* body;
	NSString* lineType;
	NSString* memberType;
	NSString* nickInfo;
	NSString* clickInfo;
	BOOL identified;
	int nickColorNumber;
}

@property (nonatomic, retain) NSString* time;
@property (nonatomic, retain) NSString* place;
@property (nonatomic, retain) NSString* nick;
@property (nonatomic, retain) NSString* body;
@property (nonatomic, retain) NSString* lineType;
@property (nonatomic, retain) NSString* memberType;
@property (nonatomic, retain) NSString* nickInfo;
@property (nonatomic, retain) NSString* clickInfo;
@property (nonatomic, assign) BOOL identified;
@property (nonatomic, assign) int nickColorNumber;

@end
