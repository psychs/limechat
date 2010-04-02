#import <Foundation/Foundation.h>

@interface NSDictionary (NSDictionaryHelper)

- (BOOL)boolForKey:(NSString*)key;
- (int)intForKey:(NSString*)key;
- (long long)longLongForKey:(NSString*)key;
- (NSString*)stringForKey:(NSString*)key;

@end


@interface NSMutableDictionary (NSMutableDictionaryHelper)

- (void)setBool:(BOOL)value forKey:(NSString*)key;
- (void)setInt:(int)value forKey:(NSString*)key;
- (void)setLongLong:(long long)value forKey:(NSString*)key;

@end
