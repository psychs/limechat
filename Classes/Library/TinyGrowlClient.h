// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Foundation/Foundation.h>


@interface TinyGrowlClient : NSObject
{
	id delegate;
	NSString* appName;
	NSArray* allNotifications;
	NSArray* defaultNotifications;
	NSImage* appIcon;
	
	NSString* clickedNotificationName;
	NSString* timedOutNotificationName;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, copy) NSString* appName;
@property (nonatomic, retain) NSArray* allNotifications;
@property (nonatomic, retain) NSArray* defaultNotifications;
@property (nonatomic, retain) NSImage* appIcon;

- (void)registerApplication;

- (void)notifyWithType:(NSString*)type
				 title:(NSString*)title
		   description:(NSString*)desc;

- (void)notifyWithType:(NSString*)type
				 title:(NSString*)title
		   description:(NSString*)desc
		  clickContext:(id)context;

- (void)notifyWithType:(NSString*)type
				 title:(NSString*)title
		   description:(NSString*)desc
		  clickContext:(id)context
				sticky:(BOOL)sticky;

- (void)notifyWithType:(NSString*)type
				 title:(NSString*)title
		   description:(NSString*)desc
		  clickContext:(id)context
				sticky:(BOOL)sticky
			  priority:(int)priority
				  icon:(NSImage*)icon;

@end


@interface NSObject (TinyGrowlClientDelegate)
- (void)tinyGrowlClient:(TinyGrowlClient*)sender didClick:(id)context;
- (void)tinyGrowlClient:(TinyGrowlClient*)sender didTimeOut:(id)context;
@end
