// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Foundation/Foundation.h>
#import "OnigRegexp.h"


@interface IgnoreItem : NSObject
{
	NSString* nick;
	NSString* text;
	BOOL useRegexForNick;
	BOOL useRegexForText;
	NSArray* channels;
	
	OnigRegexp* nickRegex;
	OnigRegexp* textRegex;
}

@property (nonatomic, retain) NSString* nick;
@property (nonatomic, retain) NSString* text;
@property (nonatomic, assign) BOOL useRegexForNick;
@property (nonatomic, assign) BOOL useRegexForText;
@property (nonatomic, retain) NSArray* channels;

@property (nonatomic, readonly) BOOL isValid;
@property (nonatomic, readonly) NSString* displayNick;
@property (nonatomic, readonly) NSString* displayText;

- (id)initWithDictionary:(NSDictionary*)dic;
- (NSDictionary*)dictionaryValue;
- (BOOL)isEqual:(id)other;

- (BOOL)checkIgnore:(NSString*)inputText nick:(NSString*)inputNick channel:(NSString*)channel;

@end
