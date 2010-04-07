#import <Cocoa/Cocoa.h>


@interface ViewTheme : NSObject
{
	NSString* name;
}

@property (nonatomic, retain) NSString* name;

+ (void)createUserDirectory;

+ (NSString*)buildResourceFileName:(NSString*)name;
+ (NSString*)buildUserFileName:(NSString*)name;
+ (NSArray*)extractFileName:(NSString*)source;

+ (NSString*)resourceBasePath;
+ (NSString*)userBasePath;

@end
