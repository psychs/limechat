// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "ViewTheme.h"
#import "Preferences.h"


@implementation ViewTheme
{
    NSString* name;
    LogTheme* log;
    OtherTheme* other;
    CustomJSFile* js;
}

@synthesize name;
@synthesize log;
@synthesize other;
@synthesize js;

- (id)init
{
    self = [super init];
    if (self) {
        log = [LogTheme new];
        other = [OtherTheme new];
        js = [CustomJSFile new];
    }
    return self;
}

- (void)dealloc
{
    [name release];
    [log release];
    [other release];
    [js release];
    [super dealloc];
}

- (void)setName:(NSString *)value
{
    if (name != value) {
        [name release];
        name = [value retain];
    }
    
    [self load];
}

- (void)load
{
    if (name) {
        NSArray* kindAndName = [ViewTheme extractFileName:[Preferences themeName]];
        if (kindAndName) {
            NSString* kind = kindAndName[0];
            NSString* fname = kindAndName[1];
            NSString* fullName = nil;
            if ([kind isEqualToString:@"resource"]) {
                fullName = [[ViewTheme resourceBasePath] stringByAppendingPathComponent:fname];
            }
            else {
                fullName = [[ViewTheme userBasePath] stringByAppendingPathComponent:fname];
            }
            
            log.fileName = [fullName stringByAppendingString:@".css"];
            other.fileName = [fullName stringByAppendingString:@".yaml"];
            js.fileName = [fullName stringByAppendingString:@".js"];
            return;
        }
    }
    
    log.fileName = nil;
    other.fileName = nil;
    js.fileName = nil;
}

- (void)reload
{
    [log reload];
    [other reload];
    [js reload];
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
    static NSString* resourceBasePath = nil;
    if (!resourceBasePath) {
        resourceBasePath = [[[[[NSBundle mainBundle] resourcePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"Themes"] retain];
    }
    return resourceBasePath;
}

+ (NSString*)userBasePath
{
    static NSString* userBasePath = nil;
    if (!userBasePath) {
        NSString* applicationSupportPath = NSHomeDirectory();
        NSArray* ary = [[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask];
        if (ary.count) {
            applicationSupportPath = [ary[0] path];
        }

        NSString* path = applicationSupportPath;
        path = [path stringByAppendingPathComponent:@"LimeChat"];
        path = [path stringByAppendingPathComponent:@"Themes"];
        userBasePath = [path retain];
    }
    return userBasePath;
}

@end
