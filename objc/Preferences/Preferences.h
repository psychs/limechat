// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import <Cocoa/Cocoa.h>


typedef enum {
	ADDRESS_DETECT_SPECIFY = 0,
	ADDRESS_DETECT_JOIN = 2,
} AddressDetectionType;

typedef enum {
	MAIN_WINDOW_LAYOUT_2_COLUMN = 0,
	MAIN_WINDOW_LAYOUT_3_COLUMN,
} MainWindowLayoutType;

typedef enum {
	KEYWORD_MATCH_PARTIAL = 0,
	KEYWORD_MATCH_EXACT,
} KeywordMatchType;

typedef enum {
	TAB_COMPLETE_NICK = 0,
	TAB_UNREAD,
	TAB_NONE = 100,
} TabActionType;


@interface Preferences : NSObject

+ (int)dccAction;
+ (AddressDetectionType)dccAddressDetectionMethod;
+ (NSString*)dccMyaddress;
+ (BOOL)autoRejoin;
+ (BOOL)confirmQuit;
+ (BOOL)connectOnDoubleclick;
+ (BOOL)disconnectOnDoubleclick;
+ (BOOL)joinOnDoubleclick;
+ (BOOL)leaveOnDoubleclick;
+ (BOOL)logTranscript;
+ (MainWindowLayoutType)mainWindowLayout;
+ (BOOL)openBrowserInBackground;
+ (NSString*)pasteCommand;
+ (NSString*)pasteSyntax;
+ (BOOL)showInlineImages;
+ (BOOL)showJoinLeave;
+ (BOOL)stopGrowlOnActive;
+ (TabActionType)tabAction;
+ (BOOL)useGrowl;
+ (BOOL)useHotkey;
+ (BOOL)keywordCurrentNick;
+ (KeywordMatchType)keywordMatchingMethod;
+ (BOOL)keywordWholeLine;

+ (NSString*)themeName;
+ (void)setThemeName:(NSString*)value;
+ (NSString*)themeLogFontName;
+ (void)setThemeLogFontName:(NSString*)value;
+ (double)themeLogFontSize;
+ (void)setThemeLogFontSize:(double)value;
+ (NSString*)themeNickFormat;
+ (BOOL)themeOverrideLogFont;
+ (BOOL)themeOverrideNickFormat;
+ (BOOL)themeOverrideTimestampFormat;
+ (NSString*)themeTimestampFormat;
+ (double)themeTransparency;

+ (int)dccFirstPort;
+ (void)setDccFirstPort:(int)value;
+ (int)dccLastPort;
+ (void)setDccLastPort:(int)value;

+ (int)maxLogLines;
+ (void)setMaxLogLines:(int)value;

+ (NSString*)transcriptFolder;
+ (void)setTranscriptFolder:(NSString*)value;

+ (NSString*)soundChanneltext;
+ (void)setSoundChanneltext:(NSString*)value;
+ (NSString*)soundDisconnect;
+ (void)setSoundDisconnect:(NSString*)value;
+ (NSString*)soundFileReceiveFailure;
+ (void)setSoundFileReceiveFailure:(NSString*)value;
+ (NSString*)soundFileReceiveRequest;
+ (void)setSoundFileReceiveRequest:(NSString*)value;
+ (NSString*)soundFileReceiveSuccess;
+ (void)setSoundFileReceiveSuccess:(NSString*)value;
+ (NSString*)soundFileSendFailure;
+ (void)setSoundFileSendFailure:(NSString*)value;
+ (NSString*)soundFileSendSuccess;
+ (void)setSoundFileSendSuccess:(NSString*)value;
+ (NSString*)soundHighlight;
+ (void)setSoundHighlight:(NSString*)value;
+ (NSString*)soundInvited;
+ (void)setSoundInvited:(NSString*)value;
+ (NSString*)soundKicked;
+ (void)setSoundKicked:(NSString*)value;
+ (NSString*)soundLogin;
+ (void)setSoundLogin:(NSString*)value;
+ (NSString*)soundNewtalk;
+ (void)setSoundNewtalk:(NSString*)value;
+ (NSString*)soundTalktext;
+ (void)setSoundTalktext:(NSString*)value;

+ (NSDictionary*)loadWorld;
+ (void)saveWorld:(NSDictionary*)value;

+ (int)hotKeyKeyCode;
+ (void)setHotKeyKeyCode:(int)value;
+ (NSUInteger)hotKeyModifierFlags;
+ (void)setHotKeyModifierFlags:(NSUInteger)value;

+ (NSArray*)keywords;
+ (NSArray*)excludeWords;
+ (NSArray*)ignoreWords;

+ (void)initPreferences;
+ (void)migrate;

+ (void)sync;

@end
