// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import <Cocoa/Cocoa.h>
#import "LogTheme.h"
#import "OtherTheme.h"
#import "CustomJSFile.h"


@interface ViewTheme : NSObject
{
	NSString* name;
	LogTheme* log;
	OtherTheme* other;
	CustomJSFile* js;
}

@property (nonatomic, retain) NSString* name;
@property (nonatomic, readonly) LogTheme* log;
@property (nonatomic, readonly) OtherTheme* other;
@property (nonatomic, readonly) CustomJSFile* js;

- (void)reload;

+ (void)createUserDirectory;

+ (NSString*)buildResourceFileName:(NSString*)name;
+ (NSString*)buildUserFileName:(NSString*)name;
+ (NSArray*)extractFileName:(NSString*)source;

+ (NSString*)resourceBasePath;
+ (NSString*)userBasePath;

@end
