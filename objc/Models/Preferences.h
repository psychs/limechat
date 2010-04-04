#import <Cocoa/Cocoa.h>


@interface NewPreferences : NSObject

+ (BOOL)boolForKey:(NSString*)key;
+ (NSString*)stringForKey:(NSString*)key;

@end
