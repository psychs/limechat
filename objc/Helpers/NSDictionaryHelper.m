#import "NSDictionaryHelper.h"
#import "NSStringHelper.h"

@implementation NSDictionary (NSDictionaryHelper)

- (BOOL)boolForKey:(NSString*)key
{
	id obj = [self objectForKey:key];
	
	int n = 0;
	if (obj && [obj respondsToSelector:@selector(intValue)]) {
		n = [obj intValue];
	}
	
	return n != 0;
}

- (int)intForKey:(NSString*)key
{
	id obj = [self objectForKey:key];
	
	int n = 0;
	if (obj && [obj respondsToSelector:@selector(intValue)]) {
		n = [obj intValue];
	}
	
	return n;
}

- (long long)longLongForKey:(NSString*)key
{
	id obj = [self objectForKey:key];
	
	long long n = 0;
	if (obj && [obj respondsToSelector:@selector(longLongValue)]) {
		n = [obj longLongValue];
	}
	
	return n;
}

- (NSString*)stringForKey:(NSString*)key
{
	id obj = [self objectForKey:key];
	
	if (obj && [obj isKindOfClass:[NSString class]]) {
		return obj;
	}
	
	return @"";
}

@end


@implementation NSMutableDictionary (NSMutableDictionaryHelper)

- (void)setBool:(BOOL)value forKey:(NSString*)key
{
	[self setObject:[NSNumber numberWithInt:value] forKey:key];
}

- (void)setInt:(int)value forKey:(NSString*)key
{
	[self setObject:[NSNumber numberWithInt:value] forKey:key];
}

- (void)setLongLong:(long long)value forKey:(NSString*)key
{
	[self setObject:[NSNumber numberWithLongLong:value] forKey:key];
}

@end
