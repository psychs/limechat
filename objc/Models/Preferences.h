// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import <Cocoa/Cocoa.h>


@interface NewPreferences : NSObject

+ (int)dccAction;
+ (void)setDccAction:(int)value;

+ (int)dccAddressDetectionMethod;
+ (void)setDccAddressDetectionMethod:(int)value;

+ (int)dccFirstPort;
+ (void)setDccFirstPort:(int)value;

+ (int)dccLastPort;
+ (void)setDccLastPort:(int)value;

+ (NSString*)dccMyaddress;
+ (void)setDccMyaddress:(NSString*)value;

+ (BOOL)autoRejoin;
+ (void)setAutoRejoin:(BOOL)value;

+ (BOOL)confirmQuit;
+ (void)setConfirmQuit:(BOOL)value;

+ (BOOL)connectOnDoubleclick;
+ (void)setConnectOnDoubleclick:(BOOL)value;

+ (BOOL)disconnectOnDoubleclick;
+ (void)setDisconnectOnDoubleclick:(BOOL)value;

+ (int)hotkeyKeyCode;
+ (void)setHotkeyKeyCode:(int)value;

+ (int)hotkeyModifierFlags;
+ (void)setHotkeyModifierFlags:(int)value;

+ (BOOL)joinOnDoubleclick;
+ (void)setJoinOnDoubleclick:(BOOL)value;

+ (BOOL)leaveOnDoubleclick;
+ (void)setLeaveOnDoubleclick:(BOOL)value;

+ (BOOL)logTranscript;
+ (void)setLogTranscript:(BOOL)value;

+ (int)mainWindowLayout;
+ (void)setMainWindowLayout:(int)value;

+ (int)maxLogLines;
+ (void)setMaxLogLines:(int)value;

+ (BOOL)openBrowserInBackground;
+ (void)setOpenBrowserInBackground:(BOOL)value;

+ (NSString*)pasteCommand;
+ (void)setPasteCommand:(NSString*)value;

+ (NSString*)pasteSyntax;
+ (void)setPasteSyntax:(NSString*)value;

+ (BOOL)showInlineImages;
+ (void)setShowInlineImages:(BOOL)value;

+ (BOOL)showJoinLeave;
+ (void)setShowJoinLeave:(BOOL)value;

+ (BOOL)stopGrowlOnActive;
+ (void)setStopGrowlOnActive:(BOOL)value;

+ (NSString*)transcriptFolder;
+ (void)setTranscriptFolder:(NSString*)value;

+ (int)tabAction;
+ (void)setTabAction:(int)value;

+ (BOOL)useGrowl;
+ (void)setUseGrowl:(BOOL)value;

+ (BOOL)useHotkey;
+ (void)setUseHotkey:(BOOL)value;

+ (BOOL)keywordCurrentNick;
+ (void)setKeywordCurrentNick:(BOOL)value;

+ (NSArray*)keywordDislikeWords;
+ (void)setKeywordDislikeWords:(NSArray*)value;

+ (NSArray*)keywordIgnoreWords;
+ (void)setKeywordIgnoreWords:(NSArray*)value;

+ (int)keywordMatchingMethod;
+ (void)setKeywordMatchingMethod:(int)value;

+ (BOOL)keywordWholeLine;
+ (void)setKeywordWholeLine:(BOOL)value;

+ (NSArray*)keywordWords;
+ (void)setKeywordWords:(NSArray*)value;

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

+ (NSString*)themeLogFontName;
+ (void)setThemeLogFontName:(NSString*)value;

+ (double)themeLogFontSize;
+ (void)setThemeLogFontSize:(double)value;

+ (NSString*)themeName;
+ (void)setThemeName:(NSString*)value;

+ (NSString*)themeNickFormat;
+ (void)setThemeNickFormat:(NSString*)value;

+ (BOOL)themeOverrideLogFont;
+ (void)setThemeOverrideLogFont:(BOOL)value;

+ (BOOL)themeOverrideNickFormat;
+ (void)setThemeOverrideNickFormat:(BOOL)value;

+ (BOOL)themeOverrideTimestampFormat;
+ (void)setThemeOverrideTimestampFormat:(BOOL)value;

+ (NSString*)themeTimestampFormat;
+ (void)setThemeTimestampFormat:(NSString*)value;

+ (double)themeTransparency;
+ (void)setThemeTransparency:(double)value;


+ (NSDictionary*)loadWorld;

+ (BOOL)boolForKey:(NSString*)key;
+ (NSString*)stringForKey:(NSString*)key;
+ (NSDictionary*)dictionaryForKey:(NSString*)key;

@end
