// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Foundation/Foundation.h>


@interface IgnoreItem : NSObject

@property (nonatomic) NSString* nick;
@property (nonatomic) NSString* text;
@property (nonatomic) BOOL useRegexForNick;
@property (nonatomic) BOOL useRegexForText;
@property (nonatomic) NSArray* channels;

@property (nonatomic, readonly) BOOL isValid;
@property (nonatomic, readonly) NSString* displayNick;
@property (nonatomic, readonly) NSString* displayText;

- (id)initWithDictionary:(NSDictionary*)dic;
- (NSDictionary*)dictionaryValue;
- (BOOL)isEqual:(id)other;

- (BOOL)checkIgnore:(NSString*)inputText nick:(NSString*)inputNick channel:(NSString*)channel;

@end
