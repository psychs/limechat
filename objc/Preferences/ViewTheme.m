#import "ViewTheme.h"


static NSString* resourceBasePath;
static NSString* userBasePath;


@interface ViewTheme (Private)
- (void)load;
@end


@implementation ViewTheme

@synthesize name;

- (id)init
{
	if (self = [super init]) {
	}
	return self;
}

- (void)dealloc
{
	[name release];
	[super dealloc];
}

- (void)setName:(NSString *)value
{
	if (name != value) {
		[name release];
		name = [value retain];
		
		[self load];
	}
}

- (void)load
{
	if (!name) return;
}

+ (void)createUserDirectory
{
	NSFileManager* fm = [NSFileManager defaultManager];
	NSString* userBase = [self userBasePath];
	
	BOOL isDir = NO;
	BOOL res = [fm fileExistsAtPath:userBase isDirectory:&isDir];
	if (res) {
		return;
	}
	
	// create directory
	[fm createDirectoryAtPath:userBase withIntermediateDirectories:YES attributes:nil error:NULL];
	
	// copy themes from resource
	NSString* resourceBase = [self resourceBasePath];
	NSArray* resourceFiles = [fm contentsOfDirectoryAtPath:resourceBase error:NULL];
	for (NSString* file in resourceFiles) {
		if ([file hasPrefix:@"Sample."]) {
			NSString* source = [resourceBase stringByAppendingPathComponent:file];
			NSString* dest = [userBase stringByAppendingPathComponent:file];
			[fm copyItemAtPath:source toPath:dest error:NULL];
		}
	}
}

+ (NSString*)buildResourceFileName:(NSString*)name
{
	return [NSString stringWithFormat:@"resource:%@", name];
}

+ (NSString*)buildUserFileName:(NSString*)name
{
	return [NSString stringWithFormat:@"user:%@", name];
}

+ (NSArray*)extractFileName:(NSString*)source
{
	NSArray* ary = [source componentsSeparatedByString:@":"];
	if (ary.count != 2) return nil;
	return ary;
}

+ (NSString*)resourceBasePath
{
	if (!resourceBasePath) {
		resourceBasePath = [[[[[NSBundle mainBundle] resourcePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"Themes"] retain];
	}
	return resourceBasePath;
}

+ (NSString*)userBasePath
{
	if (!userBasePath) {
		userBasePath = [[@"~/Library/Application Support/LimeChat/Themes" stringByExpandingTildeInPath] retain];
	}
	return userBasePath;
}

@end
