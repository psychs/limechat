// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "ViewTheme.h"
#import "Preferences.h"


@implementation ViewTheme

- (id)init
{
    self = [super init];
    if (self) {
        _log = [LogTheme new];
        _other = [OtherTheme new];
        _js = [CustomJSFile new];
    }
    return self;
}

- (void)setName:(NSString *)value
{
    _name = value;
    [self load];
}

- (void)load
{
    if (_name) {
        NSArray* kindAndName = [ViewTheme extractFileName:[Preferences themeName]];
        if (kindAndName) {
            NSString* kind = [kindAndName objectAtIndex:0];
            NSString* fname = [kindAndName objectAtIndex:1];
            NSString* fullName = nil;
            if ([kind isEqualToString:@"resource"]) {
                fullName = [[ViewTheme resourceBasePath] stringByAppendingPathComponent:fname];
            }
            else {
                fullName = [[ViewTheme userBasePath] stringByAppendingPathComponent:fname];
            }

            _log.fileName = [fullName stringByAppendingString:@".css"];
            _other.fileName = [fullName stringByAppendingString:@".yaml"];
            _js.fileName = [fullName stringByAppendingString:@".js"];
            return;
        }
    }

    _log.fileName = nil;
    _other.fileName = nil;
    _js.fileName = nil;
}

- (void)reload
{
    [_log reload];
    [_other reload];
    [_js reload];
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
        resourceBasePath = [[[[NSBundle mainBundle] resourcePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"Themes"];
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
            applicationSupportPath = [[ary objectAtIndex:0] path];
        }

        NSString* path = applicationSupportPath;
#ifdef TARGET_APP_STORE
        NSString* bundleId = [[NSBundle mainBundle] bundleIdentifier];
        path = [path stringByAppendingPathComponent:bundleId];
#else
        path = [path stringByAppendingPathComponent:@"LimeChat"];
#endif
        path = [path stringByAppendingPathComponent:@"Themes"];
        userBasePath = path;
    }
    return userBasePath;
}

@end
