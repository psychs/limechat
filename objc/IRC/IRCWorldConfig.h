// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import <Cocoa/Cocoa.h>


@interface IRCWorldConfig : NSObject <NSMutableCopying>
{
	NSMutableArray* clients;
	NSMutableArray* autoOp;
}

@property (nonatomic, readonly) NSMutableArray* clients;
@property (nonatomic, readonly) NSMutableArray* autoOp;

- (id)initWithDictionary:(NSDictionary*)dic;
- (NSMutableDictionary*)dictionaryValue;

@end
