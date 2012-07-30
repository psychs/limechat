// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Cocoa/Cocoa.h>


@class MenuController;


@interface LogPolicy : NSObject
{
    __weak MenuController* menuController;
    NSMenu* menu;
    NSMenu* urlMenu;
    NSMenu* addrMenu;
    NSMenu* memberMenu;
    NSMenu* chanMenu;
    NSString* url;
    NSString* addr;
    NSString* nick;
    NSString* chan;
}

@property (nonatomic, weak) id menuController;
@property (nonatomic, strong) NSMenu* menu;
@property (nonatomic, strong) NSMenu* urlMenu;
@property (nonatomic, strong) NSMenu* addrMenu;
@property (nonatomic, strong) NSMenu* memberMenu;
@property (nonatomic, strong) NSMenu* chanMenu;
@property (nonatomic, strong) NSString* url;
@property (nonatomic, strong) NSString* addr;
@property (nonatomic, strong) NSString* nick;
@property (nonatomic, strong) NSString* chan;

@end
