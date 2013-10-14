// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Cocoa/Cocoa.h>


@class MenuController;


@interface LogPolicy : NSObject

@property (nonatomic, weak) MenuController* menuController;
@property (nonatomic) NSMenu* menu;
@property (nonatomic) NSMenu* urlMenu;
@property (nonatomic) NSMenu* addrMenu;
@property (nonatomic) NSMenu* memberMenu;
@property (nonatomic) NSMenu* chanMenu;
@property (nonatomic) NSString* url;
@property (nonatomic) NSString* addr;
@property (nonatomic) NSString* nick;
@property (nonatomic) NSString* chan;

@end
