// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Foundation/Foundation.h>
#import "oniguruma.h"
#import "OnigRegexpUtility.h"


@class OnigResult;


@interface OnigRegexp : NSObject
{
	regex_t* _entity;
	NSString* _expression;
}

+ (OnigRegexp*)compile:(NSString*)expression;
+ (OnigRegexp*)compileIgnorecase:(NSString*)expression;
+ (OnigRegexp*)compile:(NSString*)expression ignorecase:(BOOL)ignorecase multiline:(BOOL)multiline;
+ (OnigRegexp*)compile:(NSString*)expression ignorecase:(BOOL)ignorecase multiline:(BOOL)multiline extended:(BOOL)extended;

- (OnigResult*)search:(NSString*)target;
- (OnigResult*)search:(NSString*)target start:(int)start;
- (OnigResult*)search:(NSString*)target start:(int)start end:(int)end;
- (OnigResult*)search:(NSString*)target range:(NSRange)range;

- (OnigResult*)match:(NSString*)target;
- (OnigResult*)match:(NSString*)target start:(int)start;

- (NSString*)expression;

@end


@interface OnigResult : NSObject
{
	OnigRegexp* _expression;
	OnigRegion* _region;
	NSString* _target;
}

- (NSString*)target;

- (int)count;
- (NSString*)stringAt:(int)index;
- (NSArray*)strings;
- (NSRange)rangeAt:(int)index;
- (int)locationAt:(int)index;
- (int)lengthAt:(int)index;

- (NSString*)body;
- (NSRange)bodyRange;

- (NSString*)preMatch;
- (NSString*)postMatch;

// named capture support
- (int)indexForName:(NSString*)name;
- (NSIndexSet*)indexesForName:(NSString*)name;
- (NSString*)stringForName:(NSString*)name;
- (NSArray*)stringsForName:(NSString*)name;

@end
