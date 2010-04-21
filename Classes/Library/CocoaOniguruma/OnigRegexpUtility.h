// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the new BSD license.

#import <Foundation/Foundation.h>
#import "oniguruma.h"
#import "OnigRegexp.h"


@class OnigRegexp;
@class OnigResult;


@interface NSString (OnigRegexpUtility)

// pattern is OnigRegexp or NSString

- (NSRange)rangeOfRegexp:(id)pattern;

// based on ruby's split

- (NSArray*)split;
- (NSArray*)splitByRegexp:(id)pattern;
- (NSArray*)splitByRegexp:(id)pattern limit:(int)limit;

// based on ruby's gsub

- (NSString*)replaceByRegexp:(id)pattern with:(NSString*)string;
- (NSString*)replaceAllByRegexp:(id)pattern with:(NSString*)string;

@end


@interface NSMutableString (OnigRegexpUtility)

// pattern is OnigRegexp or NSString

// based on ruby's gsub

- (NSMutableString*)replaceByRegexp:(id)pattern with:(NSString*)string;
- (NSMutableString*)replaceAllByRegexp:(id)pattern with:(NSString*)string;

@end
