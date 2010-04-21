// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the new BSD license.

#import "OnigRegexpUtility.h"


@interface NSString (OnigRegexpNSStringUtilityPrivate)
- (NSArray*)__split:(id)pattern limit:(NSNumber*)limit;
@end


@implementation NSString (OnigRegexpNSStringUtility)

- (NSRange)rangeOfRegexp:(id)pattern
{
	if (![pattern isKindOfClass:[OnigRegexp class]]) {
		pattern = [OnigRegexp compile:(NSString*)pattern];
	}
	
	OnigResult* res = [pattern search:self];
	return res ? [res bodyRange] : NSMakeRange(NSNotFound, 0);
}

- (NSArray*)split
{
	return [self splitByRegexp:@" "];
}

- (NSArray*)splitByRegexp:(id)pattern
{
	return [self __split:pattern limit:nil];
}

- (NSArray*)splitByRegexp:(id)pattern limit:(int)limit
{
	return [self __split:pattern limit:[NSNumber numberWithInt:limit]];
}

// 
// This implementation is based on ruby 1.8.
// 

- (NSArray*)__split:(id)pattern limit:(NSNumber*)limitNum
{
	NSString* target = self;
	
	if (![pattern isKindOfClass:[OnigRegexp class]]) {
		if ([pattern isEqual:@" "]) {
			// If the pattern is a single space,
			// split by contiguous white spaces,
			// where leading and trailing white spaces are ignored.

			NSRange r = [target rangeOfRegexp:@"^\\s+"];
			if (r.location != NSNotFound) {
				target = [target substringFromIndex:NSMaxRange(r)];
			}
			r = [target rangeOfRegexp:@"\\s+$"];
			if (r.location != NSNotFound) {
				target = [target substringToIndex:r.location];
			}
			pattern = [OnigRegexp compile:@"\\s+"];
		}
		else {
			pattern = [OnigRegexp compile:(NSString*)pattern];
		}
	}
	
	int i = 0;
	int limit = 0;
	
	if (limitNum) {
		limit = [limitNum intValue];
		if (limit <=0) {
			limitNum = nil;
		}
		else if (limit == 1) {
			if ([target length] == 0) return [NSArray array];
			return [NSArray arrayWithObjects:[[target copy] autorelease], nil];
		}
		i = 1;
	}
	
	NSMutableArray* array = [NSMutableArray array];
	int start = 0;
	int begin = 0;
	BOOL lastNull = NO;
	
	OnigResult* res;
	while (res = [pattern search:target start:start]) {
		NSRange range = [res bodyRange];
		int end = range.location;
		int right = NSMaxRange(range);
		
		if (start == end && range.length == 0) {
			if ([target length] == 0) {
				[array addObject:@""];
				break;
			}
			else if (lastNull) {
				[array addObject:[target substringWithRange:NSMakeRange(begin, 1)]];
				begin = start;
			}
			else {
				start++;
				lastNull = YES;
				continue;
			}
		}
		else {
			[array addObject:[target substringWithRange:NSMakeRange(begin, end-begin)]];
			begin = start = right;
		}
		lastNull = NO;
		
		if (limitNum && limit <= ++i) break;
	}
	
	if ([target length] > 0 && (limitNum || [target length] > begin || limit < 0)) {
		if ([target length] == begin) {
			[array addObject:@""];
		}
		else {
			[array addObject:[target substringFromIndex:begin]];
		}
	}
	
	if (!limitNum && limit == 0) {
		NSString* last;
		while ((last = [array lastObject]) && [last length] == 0) {
			[array removeLastObject];
		}
	}
	
	return array;
}

- (NSString*)replaceByRegexp:(id)pattern with:(NSString*)string
{
	if (![pattern isKindOfClass:[OnigRegexp class]]) {
		pattern = [OnigRegexp compile:(NSString*)pattern];
	}
	
	OnigResult* res = [pattern search:self];
	if (res) {
		NSMutableString* s = [[self mutableCopy] autorelease];
		[s replaceCharactersInRange:[res bodyRange] withString:string];
		return s;
	}
	else {
		return [[self mutableCopy] autorelease];
	}
}

// 
// This implementation is based on ruby 1.8.
// 

- (NSString*)replaceAllByRegexp:(id)pattern with:(NSString*)string
{
	if (![pattern isKindOfClass:[OnigRegexp class]]) {
		pattern = [OnigRegexp compile:(NSString*)pattern];
	}
		
	OnigResult* res = [pattern search:self];
	if (!res) {
		return [[self mutableCopy] autorelease];
	}
	
	NSMutableString* s = [NSMutableString string];
	int offset = 0;
	
	do {
		NSRange range = [res bodyRange];
		int len = range.location-offset;
		if (len > 0) [s appendString:[self substringWithRange:NSMakeRange(offset, len)]];
		[s appendString:string];
		
		offset = NSMaxRange(range);
		if (range.length == 0) {
			// consume 1 character at least
			if ([self length] <= offset) break;
			[s appendString:[self substringWithRange:NSMakeRange(offset, 1)]];
			offset++;
		}
		if ([self length] < offset) break;
		
	} while (res = [pattern search:self start:offset]);
	
	if (offset < [self length]) {
		[s appendString:[self substringFromIndex:offset]];
	}
	
	return s;
}

@end


@implementation NSMutableString (OnigRegexpNSMutableStringUtility)

- (NSMutableString*)replaceByRegexp:(id)pattern with:(NSString*)string
{
	return (NSMutableString*)[super replaceByRegexp:pattern with:string];
}

- (NSMutableString*)replaceAllByRegexp:(id)pattern with:(NSString*)string
{
	return (NSMutableString*)[super replaceAllByRegexp:pattern with:string];
}

@end
