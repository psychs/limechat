// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the new BSD license.

#import <Foundation/Foundation.h>


@interface IgnoreItem : NSObject
{
	NSString* nick;
	NSString* text;
	BOOL useRegexForNick;
	BOOL useRegexForText;
	NSArray* channels;
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

@end
