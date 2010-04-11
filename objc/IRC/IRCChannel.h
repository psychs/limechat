// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

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
{
	IRCClient* client;
	IRCChannelConfig* config;
	
	IRCChannelMode* mode;
	NSMutableArray* members;
	NSString* topic;
	NSString* storedTopic;
	BOOL isActive;
	BOOL isOp;
	BOOL isModeInit;
	BOOL isNamesInit;
	BOOL isWhoInit;
	
	BOOL terminating;
	
	FileLogger* logFile;
	NSDateComponents* logDate;
	
	ChannelDialog* propertyDialog;
}

@property (nonatomic, assign) IRCClient* client;
@property (nonatomic, readonly) IRCChannelConfig* config;
@property (nonatomic, assign) NSString* name;
@property (nonatomic, readonly) NSString* password;
@property (nonatomic, readonly) IRCChannelMode* mode;
@property (nonatomic, readonly) NSMutableArray* members;
@property (nonatomic, readonly) NSString* channelTypeString;
@property (nonatomic, retain) NSString* topic;
@property (nonatomic, retain) NSString* storedTopic;
@property (nonatomic, assign) BOOL isActive;
@property (nonatomic, assign) BOOL isOp;
@property (nonatomic, assign) BOOL isModeInit;
@property (nonatomic, assign) BOOL isNamesInit;
@property (nonatomic, assign) BOOL isWhoInit;
@property (nonatomic, readonly) BOOL isChannel;
@property (nonatomic, readonly) BOOL isTalk;

@property (nonatomic, retain) ChannelDialog* propertyDialog;

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
