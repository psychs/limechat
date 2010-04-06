// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import <Cocoa/Cocoa.h>


@interface NewPreferences : NSObject

+ (int)dccAction;
+ (int)dccAddressDetectionMethod;
+ (int)dccFirstPort;
+ (int)dccLastPort;
+ (NSString*)dccMyaddress;
+ (BOOL)autoRejoin;
+ (BOOL)confirmQuit;
+ (BOOL)connectOnDoubleclick;
+ (BOOL)disconnectOnDoubleclick;
+ (int)hotkeyKeyCode;
+ (int)hotkeyModifierFlags;
+ (BOOL)joinOnDoubleclick;
+ (BOOL)leaveOnDoubleclick;
+ (BOOL)logTranscript;
+ (int)mainWindowLayout;
+ (int)maxLogLines;
+ (BOOL)openBrowserInBackground;
+ (NSString*)pasteCommand;
+ (NSString*)pasteSyntax;
+ (BOOL)showInlineImages;
+ (BOOL)showJoinLeave;
+ (BOOL)stopGrowlOnActive;
+ (NSString*)transcriptFolder;
+ (int)tabAction;
+ (BOOL)useGrowl;
+ (BOOL)useHotkey;
+ (BOOL)keywordCurrentNick;
+ (NSArray*)keywordDislikeWords;
+ (NSArray*)keywordIgnoreWords;
+ (int)keywordMatchingMethod;
+ (BOOL)keywordWholeLine;
+ (NSArray*)keywordWords;
+ (NSString*)soundChanneltext;
+ (NSString*)soundDisconnect;
+ (NSString*)soundFileReceiveFailure;
+ (NSString*)soundFileReceiveRequest;
+ (NSString*)soundFileReceiveSuccess;
+ (NSString*)soundFileSendFailure;
+ (NSString*)soundFileSendSuccess;
+ (NSString*)soundHighlight;
+ (NSString*)soundInvited;
+ (NSString*)soundKicked;
+ (NSString*)soundLogin;
+ (NSString*)soundNewtalk;
+ (NSString*)soundTalktext;
+ (NSString*)themeLogFontName;
+ (double)themeLogFontSize;
+ (NSString*)themeName;
+ (NSString*)themeNickFormat;
+ (BOOL)themeOverrideLogFont;
+ (BOOL)themeOverrideNickFormat;
+ (BOOL)themeOverrideTimestampFormat;
+ (NSString*)themeTimestampFormat;
+ (double)themeTransparency;

+ (NSDictionary*)loadWorld;

+ (BOOL)boolForKey:(NSString*)key;
+ (NSString*)stringForKey:(NSString*)key;
+ (NSDictionary*)dictionaryForKey:(NSString*)key;

@end
