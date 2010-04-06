// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "Preferences.h"


@implementation NewPreferences

+ (int)dccAction
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.Dcc.action"];
	if (!obj) return 1;
	return [obj intValue];
}

+ (void)setDccAction:(int)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setInteger:value forKey:@"Preferences.Dcc.action"];
}

+ (int)dccAddressDetectionMethod
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.Dcc.address_detection_method"];
	if (!obj) return 2;
	return [obj intValue];
}

+ (void)setDccAddressDetectionMethod:(int)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setInteger:value forKey:@"Preferences.Dcc.address_detection_method"];
}

+ (int)dccFirstPort
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.Dcc.first_port"];
	if (!obj) return 1096;
	return [obj intValue];
}

+ (void)setDccFirstPort:(int)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setInteger:value forKey:@"Preferences.Dcc.first_port"];
}

+ (int)dccLastPort
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.Dcc.last_port"];
	if (!obj) return 1115;
	return [obj intValue];
}

+ (void)setDccLastPort:(int)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setInteger:value forKey:@"Preferences.Dcc.last_port"];
}

+ (NSString*)dccMyaddress
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.Dcc.myaddress"];
	if (!obj) return @"";
	return [obj objectValue];
}

+ (void)setDccMyaddress:(NSString*)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setObject:value forKey:@"Preferences.Dcc.myaddress"];
}

+ (BOOL)autoRejoin
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.General.auto_rejoin"];
	if (!obj) return NO;
	return [obj boolValue];
}

+ (void)setAutoRejoin:(BOOL)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setBool:value forKey:@"Preferences.General.auto_rejoin"];
}

+ (BOOL)confirmQuit
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.General.confirm_quit"];
	if (!obj) return YES;
	return [obj boolValue];
}

+ (void)setConfirmQuit:(BOOL)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setBool:value forKey:@"Preferences.General.confirm_quit"];
}

+ (BOOL)connectOnDoubleclick
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.General.connect_on_doubleclick"];
	if (!obj) return NO;
	return [obj boolValue];
}

+ (void)setConnectOnDoubleclick:(BOOL)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setBool:value forKey:@"Preferences.General.connect_on_doubleclick"];
}

+ (BOOL)disconnectOnDoubleclick
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.General.disconnect_on_doubleclick"];
	if (!obj) return NO;
	return [obj boolValue];
}

+ (void)setDisconnectOnDoubleclick:(BOOL)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setBool:value forKey:@"Preferences.General.disconnect_on_doubleclick"];
}

+ (int)hotkeyKeyCode
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.General.hotkey_key_code"];
	if (!obj) return 0;
	return [obj intValue];
}

+ (void)setHotkeyKeyCode:(int)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setInteger:value forKey:@"Preferences.General.hotkey_key_code"];
}

+ (int)hotkeyModifierFlags
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.General.hotkey_modifier_flags"];
	if (!obj) return 0;
	return [obj intValue];
}

+ (void)setHotkeyModifierFlags:(int)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setInteger:value forKey:@"Preferences.General.hotkey_modifier_flags"];
}

+ (BOOL)joinOnDoubleclick
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.General.join_on_doubleclick"];
	if (!obj) return NO;
	return [obj boolValue];
}

+ (void)setJoinOnDoubleclick:(BOOL)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setBool:value forKey:@"Preferences.General.join_on_doubleclick"];
}

+ (BOOL)leaveOnDoubleclick
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.General.leave_on_doubleclick"];
	if (!obj) return NO;
	return [obj boolValue];
}

+ (void)setLeaveOnDoubleclick:(BOOL)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setBool:value forKey:@"Preferences.General.leave_on_doubleclick"];
}

+ (BOOL)logTranscript
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.General.log_transcript"];
	if (!obj) return NO;
	return [obj boolValue];
}

+ (void)setLogTranscript:(BOOL)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setBool:value forKey:@"Preferences.General.log_transcript"];
}

+ (int)mainWindowLayout
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.General.main_window_layout"];
	if (!obj) return 0;
	return [obj intValue];
}

+ (void)setMainWindowLayout:(int)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setInteger:value forKey:@"Preferences.General.main_window_layout"];
}

+ (int)maxLogLines
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.General.max_log_lines"];
	if (!obj) return 300;
	return [obj intValue];
}

+ (void)setMaxLogLines:(int)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setInteger:value forKey:@"Preferences.General.max_log_lines"];
}

+ (BOOL)openBrowserInBackground
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.General.open_browser_in_background"];
	if (!obj) return YES;
	return [obj boolValue];
}

+ (void)setOpenBrowserInBackground:(BOOL)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setBool:value forKey:@"Preferences.General.open_browser_in_background"];
}

+ (NSString*)pasteCommand
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.General.paste_command"];
	if (!obj) return @"privmsg";
	return [obj objectValue];
}

+ (void)setPasteCommand:(NSString*)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setObject:value forKey:@"Preferences.General.paste_command"];
}

+ (NSString*)pasteSyntax
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.General.paste_syntax"];
	if (!obj) return [[[ud objectForKey:@"AppleLanguages"] objectAtIndex:0] isEqualToString:@"ja"] ? @"notice" : @"privmsg";
	return [obj objectValue];
}

+ (void)setPasteSyntax:(NSString*)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setObject:value forKey:@"Preferences.General.paste_syntax"];
}

+ (BOOL)showInlineImages
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.General.show_inline_images"];
	if (!obj) return YES;
	return [obj boolValue];
}

+ (void)setShowInlineImages:(BOOL)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setBool:value forKey:@"Preferences.General.show_inline_images"];
}

+ (BOOL)showJoinLeave
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.General.show_join_leave"];
	if (!obj) return YES;
	return [obj boolValue];
}

+ (void)setShowJoinLeave:(BOOL)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setBool:value forKey:@"Preferences.General.show_join_leave"];
}

+ (BOOL)stopGrowlOnActive
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.General.stop_growl_on_active"];
	if (!obj) return NO;
	return [obj boolValue];
}

+ (void)setStopGrowlOnActive:(BOOL)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setBool:value forKey:@"Preferences.General.stop_growl_on_active"];
}

+ (NSString*)transcriptFolder
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.General.transcript_folder"];
	if (!obj) return @"~/Documents/LimeChat Transcripts";
	return [obj objectValue];
}

+ (void)setTranscriptFolder:(NSString*)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setObject:value forKey:@"Preferences.General.transcript_folder"];
}

+ (int)tabAction
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.General.tab_action"];
	if (!obj) return 0;
	return [obj intValue];
}

+ (void)setTabAction:(int)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setInteger:value forKey:@"Preferences.General.tab_action"];
}

+ (BOOL)useGrowl
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.General.use_growl"];
	if (!obj) return YES;
	return [obj boolValue];
}

+ (void)setUseGrowl:(BOOL)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setBool:value forKey:@"Preferences.General.use_growl"];
}

+ (BOOL)useHotkey
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.General.use_hotkey"];
	if (!obj) return NO;
	return [obj boolValue];
}

+ (void)setUseHotkey:(BOOL)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setBool:value forKey:@"Preferences.General.use_hotkey"];
}

+ (BOOL)keywordCurrentNick
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.Keyword.current_nick"];
	if (!obj) return YES;
	return [obj boolValue];
}

+ (void)setKeywordCurrentNick:(BOOL)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setBool:value forKey:@"Preferences.Keyword.current_nick"];
}

+ (NSArray*)keywordDislikeWords
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud objectForKey:@"Preferences.Keyword.dislike_words"];
}

+ (void)setKeywordDislikeWords:(NSArray*)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setObject:value forKey:@"Preferences.Keyword.dislike_words"];
}

+ (NSArray*)keywordIgnoreWords
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud objectForKey:@"Preferences.Keyword.ignore_words"];
}

+ (void)setKeywordIgnoreWords:(NSArray*)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setObject:value forKey:@"Preferences.Keyword.ignore_words"];
}

+ (int)keywordMatchingMethod
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.Keyword.matching_method"];
	if (!obj) return 0;
	return [obj intValue];
}

+ (void)setKeywordMatchingMethod:(int)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setInteger:value forKey:@"Preferences.Keyword.matching_method"];
}

+ (BOOL)keywordWholeLine
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.Keyword.whole_line"];
	if (!obj) return NO;
	return [obj boolValue];
}

+ (void)setKeywordWholeLine:(BOOL)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setBool:value forKey:@"Preferences.Keyword.whole_line"];
}

+ (NSArray*)keywordWords
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud objectForKey:@"Preferences.Keyword.words"];
}

+ (void)setKeywordWords:(NSArray*)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setObject:value forKey:@"Preferences.Keyword.words"];
}

+ (NSString*)soundChanneltext
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud objectForKey:@"Preferences.Sound.channeltext"];
}

+ (void)setSoundChanneltext:(NSString*)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setObject:value forKey:@"Preferences.Sound.channeltext"];
}

+ (NSString*)soundDisconnect
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud objectForKey:@"Preferences.Sound.disconnect"];
}

+ (void)setSoundDisconnect:(NSString*)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setObject:value forKey:@"Preferences.Sound.disconnect"];
}

+ (NSString*)soundFileReceiveFailure
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud objectForKey:@"Preferences.Sound.file_receive_failure"];
}

+ (void)setSoundFileReceiveFailure:(NSString*)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setObject:value forKey:@"Preferences.Sound.file_receive_failure"];
}

+ (NSString*)soundFileReceiveRequest
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud objectForKey:@"Preferences.Sound.file_receive_request"];
}

+ (void)setSoundFileReceiveRequest:(NSString*)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setObject:value forKey:@"Preferences.Sound.file_receive_request"];
}

+ (NSString*)soundFileReceiveSuccess
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud objectForKey:@"Preferences.Sound.file_receive_success"];
}

+ (void)setSoundFileReceiveSuccess:(NSString*)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setObject:value forKey:@"Preferences.Sound.file_receive_success"];
}

+ (NSString*)soundFileSendFailure
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud objectForKey:@"Preferences.Sound.file_send_failure"];
}

+ (void)setSoundFileSendFailure:(NSString*)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setObject:value forKey:@"Preferences.Sound.file_send_failure"];
}

+ (NSString*)soundFileSendSuccess
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud objectForKey:@"Preferences.Sound.file_send_success"];
}

+ (void)setSoundFileSendSuccess:(NSString*)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setObject:value forKey:@"Preferences.Sound.file_send_success"];
}

+ (NSString*)soundHighlight
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud objectForKey:@"Preferences.Sound.highlight"];
}

+ (void)setSoundHighlight:(NSString*)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setObject:value forKey:@"Preferences.Sound.highlight"];
}

+ (NSString*)soundInvited
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud objectForKey:@"Preferences.Sound.invited"];
}

+ (void)setSoundInvited:(NSString*)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setObject:value forKey:@"Preferences.Sound.invited"];
}

+ (NSString*)soundKicked
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud objectForKey:@"Preferences.Sound.kicked"];
}

+ (void)setSoundKicked:(NSString*)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setObject:value forKey:@"Preferences.Sound.kicked"];
}

+ (NSString*)soundLogin
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud objectForKey:@"Preferences.Sound.login"];
}

+ (void)setSoundLogin:(NSString*)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setObject:value forKey:@"Preferences.Sound.login"];
}

+ (NSString*)soundNewtalk
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud objectForKey:@"Preferences.Sound.newtalk"];
}

+ (void)setSoundNewtalk:(NSString*)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setObject:value forKey:@"Preferences.Sound.newtalk"];
}

+ (NSString*)soundTalktext
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud objectForKey:@"Preferences.Sound.talktext"];
}

+ (void)setSoundTalktext:(NSString*)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setObject:value forKey:@"Preferences.Sound.talktext"];
}

+ (NSString*)themeLogFontName
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.Theme.log_font_name"];
	if (!obj) return @"Lucida Grande";
	return [obj objectValue];
}

+ (void)setThemeLogFontName:(NSString*)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setObject:value forKey:@"Preferences.Theme.log_font_name"];
}

+ (double)themeLogFontSize
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.Theme.log_font_size"];
	if (!obj) return 12;
	return [obj doubleValue];
}

+ (void)setThemeLogFontSize:(double)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setDouble:value forKey:@"Preferences.Theme.log_font_size"];
}

+ (NSString*)themeName
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.Theme.name"];
	if (!obj) return @"resource:Default";
	return [obj objectValue];
}

+ (void)setThemeName:(NSString*)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setObject:value forKey:@"Preferences.Theme.name"];
}

+ (NSString*)themeNickFormat
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.Theme.nick_format"];
	if (!obj) return @"%n: ";
	return [obj objectValue];
}

+ (void)setThemeNickFormat:(NSString*)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setObject:value forKey:@"Preferences.Theme.nick_format"];
}

+ (BOOL)themeOverrideLogFont
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.Theme.override_log_font"];
	if (!obj) return NO;
	return [obj boolValue];
}

+ (void)setThemeOverrideLogFont:(BOOL)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setBool:value forKey:@"Preferences.Theme.override_log_font"];
}

+ (BOOL)themeOverrideNickFormat
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.Theme.override_nick_format"];
	if (!obj) return NO;
	return [obj boolValue];
}

+ (void)setThemeOverrideNickFormat:(BOOL)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setBool:value forKey:@"Preferences.Theme.override_nick_format"];
}

+ (BOOL)themeOverrideTimestampFormat
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.Theme.override_timestamp_format"];
	if (!obj) return NO;
	return [obj boolValue];
}

+ (void)setThemeOverrideTimestampFormat:(BOOL)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setBool:value forKey:@"Preferences.Theme.override_timestamp_format"];
}

+ (NSString*)themeTimestampFormat
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.Theme.timestamp_format"];
	if (!obj) return @"%H:%M";
	return [obj objectValue];
}

+ (void)setThemeTimestampFormat:(NSString*)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setObject:value forKey:@"Preferences.Theme.timestamp_format"];
}

+ (double)themeTransparency
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.Theme.transparency"];
	if (!obj) return 1;
	return [obj doubleValue];
}

+ (void)setThemeTransparency:(double)value
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setDouble:value forKey:@"Preferences.Theme.transparency"];
}


+ (NSDictionary*)loadWorld
{
	return [self dictionaryForKey:@"world"];
}

+ (BOOL)boolForKey:(NSString*)key
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud boolForKey:key];
}

+ (NSString*)stringForKey:(NSString*)key
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	NSString* s = [ud objectForKey:key];
	if ([s isKindOfClass:[NSString class]]) {
		return s;
	}
	return nil;
}

+ (NSDictionary*)dictionaryForKey:(NSString*)key
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	NSDictionary* s = [ud objectForKey:key];
	if ([s isKindOfClass:[NSDictionary class]]) {
		return s;
	}
	return nil;
}

@end
