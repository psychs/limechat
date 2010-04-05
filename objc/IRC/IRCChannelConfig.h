// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import <Cocoa/Cocoa.h>


@interface IRCChannelConfig : NSObject
{
	NSString* name;
	NSString* password;
	
	BOOL autoJoin;
	BOOL logToConsole;
	BOOL growl;
	
	NSString* mode;
	NSString* topic;
	
	NSMutableArray* autoOp;
}

@property (nonatomic, retain) NSString* name;
@property (nonatomic, retain) NSString* password;

@property (nonatomic, assign) BOOL autoJoin;
@property (nonatomic, assign) BOOL logToConsole;
@property (nonatomic, assign) BOOL growl;

@property (nonatomic, retain) NSString* mode;
@property (nonatomic, retain) NSString* topic;

@property (nonatomic, readonly) NSMutableArray* autoOp;

- (id)initWithDictionary:(NSDictionary*)dic;
- (NSDictionary*)dictionaryValue;

@end
