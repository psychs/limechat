// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "NSDictionaryHelper.h"
#import "NSStringHelper.h"

@implementation NSDictionary (NSDictionaryHelper)

- (BOOL)boolForKey:(NSString*)key
{
	id obj = [self objectForKey:key];
	if ([obj respondsToSelector:@selector(boolValue)]) {
		return [obj boolValue];
	}
	return NO;
}

- (int)intForKey:(NSString*)key
{
	id obj = [self objectForKey:key];
	if ([obj respondsToSelector:@selector(intValue)]) {
		return [obj intValue];
	}
	return 0;
}

- (long long)longLongForKey:(NSString*)key
{
	id obj = [self objectForKey:key];
	if ([obj respondsToSelector:@selector(longLongValue)]) {
		return [obj longLongValue];
	}
	return 0;
}

- (double)doubleForKey:(NSString*)key
{
	id obj = [self objectForKey:key];
	if ([obj respondsToSelector:@selector(doubleValue)]) {
		return [obj doubleValue];
	}
	return 0;
}

- (NSString*)stringForKey:(NSString*)key
{
	id obj = [self objectForKey:key];
	if ([obj isKindOfClass:[NSString class]]) {
		return obj;
	}
	return nil;
}

- (NSDictionary*)dictionaryForKey:(NSString*)key
{
	id obj = [self objectForKey:key];
	if ([obj isKindOfClass:[NSDictionary class]]) {
		return obj;
	}
	return nil;
}

- (NSArray*)arrayForKey:(NSString*)key
{
	id obj = [self objectForKey:key];
	if ([obj isKindOfClass:[NSArray class]]) {
		return obj;
	}
	return nil;
}

@end


@implementation NSMutableDictionary (NSMutableDictionaryHelper)

- (void)setBool:(BOOL)value forKey:(NSString*)key
{
	[self setObject:[NSNumber numberWithBool:value] forKey:key];
}

- (void)setInt:(int)value forKey:(NSString*)key
{
	[self setObject:[NSNumber numberWithInt:value] forKey:key];
}

- (void)setLongLong:(long long)value forKey:(NSString*)key
{
	[self setObject:[NSNumber numberWithLongLong:value] forKey:key];
}

- (void)setDouble:(double)value forKey:(NSString*)key
{
	[self setObject:[NSNumber numberWithDouble:value] forKey:key];
}

@end
