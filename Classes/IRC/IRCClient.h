// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import <Cocoa/Cocoa.h>
#import "IRCTreeItem.h"
#import "IRCClientConfig.h"
#import "IRCChannel.h"
#import "IRCConnection.h"
#import "IRCISupportInfo.h"
#import "IRCUserMode.h"
#import "Preferences.h"
#import "LogController.h"
#import "ServerDialog.h"
#import "ListDialog.h"
#import "Timer.h"
#import "HostResolver.h"


@class IRCWorld;


typedef enum {
	CONNECT_NORMAL,
	CONNECT_RECONNECT,
	CONNECT_RETRY,
} ConnectMode;


@interface IRCClient : IRCTreeItem
{
	IRCWorld* world;
	IRCClientConfig* config;
	
	NSMutableArray* channels;
	IRCISupportInfo* isupport;
	IRCUserMode* myMode;
	
	IRCConnection* conn;
	int connectDelay;
	BOOL reconnectEnabled;
	BOOL retryEnabled;
	
	BOOL isConnecting;
	BOOL isConnected;
	BOOL isLoggedIn;
	BOOL isQuitting;
	NSStringEncoding encoding;
	
	NSString* inputNick;
	NSString* sentNick;
	NSString* myNick;
	int tryingNickNumber;
	
	NSString* serverHostname;
	BOOL registeringToNickServ;
	BOOL inWhois;
	BOOL inList;
	BOOL identifyMsg;
	BOOL identifyCTCP;
	
	AddressDetectionType addressDetectionMethod;
	HostResolver* nameResolver;
	NSString* joinMyAddress;
	NSString* myAddress;
	CFAbsoluteTime lastCTCPTime;
	
	Timer* pongTimer;
	Timer* quitTimer;
	Timer* reconnectTimer;
	Timer* retryTimer;
	Timer* autoJoinTimer;
	Timer* commandQueueTimer;
	NSMutableArray* commandQueue;
	
	IRCChannel* lastSelectedChannel;
	
	NSMutableArray* whoisDialogs;
	ListDialog* channelListDialog;
	ServerDialog* propertyDialog;
}

@property (nonatomic, assign) IRCWorld* world;
@property (nonatomic, readonly) NSString* name;
@property (nonatomic, readonly) IRCClientConfig* config;
@property (nonatomic, readonly) IRCISupportInfo* isupport;
@property (nonatomic, readonly) IRCUserMode* myMode;
@property (nonatomic, readonly) NSMutableArray* channels;
@property (nonatomic, readonly) BOOL isConnecting;
@property (nonatomic, readonly) BOOL isConnected;
@property (nonatomic, readonly) BOOL isReconnecting;
@property (nonatomic, readonly) BOOL isLoggedIn;
@property (nonatomic, readonly) NSString* myNick;
@property (nonatomic, readonly) NSString* myAddress;
@property (nonatomic, retain) IRCChannel* lastSelectedChannel;
@property (nonatomic, retain) ServerDialog* propertyDialog;

- (void)setup:(IRCClientConfig*)seed;
- (void)updateConfig:(IRCClientConfig*)seed;
- (IRCClientConfig*)storedConfig;
- (NSMutableDictionary*)dictionaryValue;

- (void)autoConnect:(int)delay;
- (void)onTimer;
- (void)terminate;
- (void)closeDialogs;
- (void)preferencesChanged;

- (void)connect;
- (void)connect:(ConnectMode)mode;
- (void)disconnect;
- (void)quit;
- (void)quit:(NSString*)comment;
- (void)cancelReconnect;

- (void)changeNick:(NSString*)newNick;
- (void)joinChannel:(IRCChannel*)channel;
- (void)joinChannel:(IRCChannel*)channel password:(NSString*)password;
- (void)partChannel:(IRCChannel*)channel;
- (void)sendWhois:(NSString*)nick;
- (void)changeOp:(IRCChannel*)channel users:(NSArray*)users mode:(char)mode value:(BOOL)value;
- (void)kick:(IRCChannel*)channel target:(NSString*)nick;
- (void)sendFile:(NSString*)nick port:(int)port fileName:(NSString*)fileName size:(long long)size;
- (void)sendCTCPQuery:(NSString*)target command:(NSString*)command text:(NSString*)text;
- (void)sendCTCPReply:(NSString*)target command:(NSString*)command text:(NSString*)text;
- (void)sendCTCPPing:(NSString*)target;

- (BOOL)inputText:(NSString*)s command:(NSString*)command;
- (void)sendText:(NSString*)s command:(NSString*)command channel:(IRCChannel*)channel;
- (BOOL)sendCommand:(NSString*)s;
- (BOOL)sendCommand:(NSString*)s completeTarget:(BOOL)completeTarget target:(NSString*)target;

- (void)sendLine:(NSString*)str;
- (void)send:(NSString*)str, ...;

- (IRCChannel*)findChannel:(NSString*)name;
- (int)indexOfTalkChannel;

- (void)createChannelListDialog;

@end
