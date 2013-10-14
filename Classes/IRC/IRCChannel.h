// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Cocoa/Cocoa.h>
#import "IRCTreeItem.h"
#import "IRCChannelConfig.h"
#import "LogController.h"
#import "IRCUser.h"
#import "IRCChannelMode.h"
#import "ChannelDialog.h"
#import "FileLogger.h"


@class IRCClient;


@interface IRCChannel : IRCTreeItem

@property (nonatomic, weak) IRCClient* client;
@property (nonatomic, readonly) IRCChannelConfig* config;
@property (nonatomic) NSString* name;
@property (nonatomic, readonly) NSString* password;
@property (nonatomic, readonly) IRCChannelMode* mode;
@property (nonatomic, readonly) NSMutableArray* members;
@property (nonatomic, readonly) NSString* channelTypeString;
@property (nonatomic) NSString* topic;
@property (nonatomic) NSString* storedTopic;
@property (nonatomic) BOOL isActive;
@property (nonatomic) BOOL isOp;
@property (nonatomic) BOOL isModeInit;
@property (nonatomic) BOOL isNamesInit;
@property (nonatomic) BOOL isWhoInit;
@property (nonatomic, readonly) BOOL isChannel;
@property (nonatomic, readonly) BOOL isTalk;

@property (nonatomic) ChannelDialog* propertyDialog;

- (void)setup:(IRCChannelConfig*)seed;
- (void)updateConfig:(IRCChannelConfig*)seed;
- (void)updateAutoOp:(IRCChannelConfig*)seed;
- (NSMutableDictionary*)dictionaryValue;

- (void)terminate;
- (void)closeDialogs;
- (void)preferencesChanged;

- (void)activate;
- (void)deactivate;

- (BOOL)print:(LogLine*)line;

- (void)addMember:(IRCUser*)user;
- (void)addMember:(IRCUser*)user reload:(BOOL)reload;
- (void)removeMember:(NSString*)nick;
- (void)removeMember:(NSString*)nick reload:(BOOL)reload;
- (void)renameMember:(NSString*)fromNick to:(NSString*)toNick;
- (void)updateOrAddMember:(IRCUser*)user;
- (void)changeMember:(NSString*)nick mode:(char)mode value:(BOOL)value;
- (void)clearMembers;
- (int)indexOfMember:(NSString*)nick;
- (IRCUser*)memberAtIndex:(int)index;
- (IRCUser*)findMember:(NSString*)nick;
- (int)numberOfMembers;
- (void)reloadMemberList;

@end
