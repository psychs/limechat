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

+ (int)dccAddressDetectionMethod
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.Dcc.address_detection_method"];
	if (!obj) return 2;
	return [obj intValue];
}

+ (int)dccFirstPort
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.Dcc.first_port"];
	if (!obj) return 1096;
	return [obj intValue];
}

+ (int)dccLastPort
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.Dcc.last_port"];
	if (!obj) return 1115;
	return [obj intValue];
}

+ (NSString*)dccMyaddress
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.Dcc.myaddress"];
	if (!obj) return @"";
	return [obj objectValue];
}

+ (BOOL)autoRejoin
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.General.auto_rejoin"];
	if (!obj) return NO;
	return [obj boolValue];
}

+ (BOOL)confirmQuit
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.General.confirm_quit"];
	if (!obj) return YES;
	return [obj boolValue];
}

+ (BOOL)connectOnDoubleclick
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.General.connect_on_doubleclick"];
	if (!obj) return NO;
	return [obj boolValue];
}

+ (BOOL)disconnectOnDoubleclick
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.General.disconnect_on_doubleclick"];
	if (!obj) return NO;
	return [obj boolValue];
}

+ (int)hotkeyKeyCode
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.General.hotkey_key_code"];
	if (!obj) return 0;
	return [obj intValue];
}

+ (int)hotkeyModifierFlags
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.General.hotkey_modifier_flags"];
	if (!obj) return 0;
	return [obj intValue];
}

+ (BOOL)joinOnDoubleclick
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.General.join_on_doubleclick"];
	if (!obj) return NO;
	return [obj boolValue];
}

+ (BOOL)leaveOnDoubleclick
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.General.leave_on_doubleclick"];
	if (!obj) return NO;
	return [obj boolValue];
}

+ (BOOL)logTranscript
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.General.log_transcript"];
	if (!obj) return NO;
	return [obj boolValue];
}

+ (int)mainWindowLayout
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.General.main_window_layout"];
	if (!obj) return 0;
	return [obj intValue];
}

+ (int)maxLogLines
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.General.max_log_lines"];
	if (!obj) return 300;
	return [obj intValue];
}

+ (BOOL)openBrowserInBackground
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.General.open_browser_in_background"];
	if (!obj) return YES;
	return [obj boolValue];
}

+ (NSString*)pasteCommand
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.General.paste_command"];
	if (!obj) return @"privmsg";
	return [obj objectValue];
}

+ (NSString*)pasteSyntax
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.General.paste_syntax"];
	if (!obj) return [[[ud objectForKey:@"AppleLanguages"] objectAtIndex:0] isEqualToString:@"ja"] ? @"notice" : @"privmsg";
	return [obj objectValue];
}

+ (BOOL)showInlineImages
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.General.show_inline_images"];
	if (!obj) return YES;
	return [obj boolValue];
}

+ (BOOL)showJoinLeave
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.General.show_join_leave"];
	if (!obj) return YES;
	return [obj boolValue];
}

+ (BOOL)stopGrowlOnActive
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.General.stop_growl_on_active"];
	if (!obj) return NO;
	return [obj boolValue];
}

+ (NSString*)transcriptFolder
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.General.transcript_folder"];
	if (!obj) return @"~/Documents/LimeChat Transcripts";
	return [obj objectValue];
}

+ (int)tabAction
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.General.tab_action"];
	if (!obj) return 0;
	return [obj intValue];
}

+ (BOOL)useGrowl
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.General.use_growl"];
	if (!obj) return YES;
	return [obj boolValue];
}

+ (BOOL)useHotkey
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.General.use_hotkey"];
	if (!obj) return NO;
	return [obj boolValue];
}

+ (BOOL)keywordCurrentNick
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.Keyword.current_nick"];
	if (!obj) return YES;
	return [obj boolValue];
}

+ (NSArray*)keywordDislikeWords
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud objectForKey:@"Preferences.Keyword.dislike_words"];
}

+ (NSArray*)keywordIgnoreWords
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud objectForKey:@"Preferences.Keyword.ignore_words"];
}

+ (int)keywordMatchingMethod
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.Keyword.matching_method"];
	if (!obj) return 0;
	return [obj intValue];
}

+ (BOOL)keywordWholeLine
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.Keyword.whole_line"];
	if (!obj) return NO;
	return [obj boolValue];
}

+ (NSArray*)keywordWords
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud objectForKey:@"Preferences.Keyword.words"];
}

+ (NSString*)soundChanneltext
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud objectForKey:@"Preferences.Sound.channeltext"];
}

+ (NSString*)soundDisconnect
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud objectForKey:@"Preferences.Sound.disconnect"];
}

+ (NSString*)soundFileReceiveFailure
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud objectForKey:@"Preferences.Sound.file_receive_failure"];
}

+ (NSString*)soundFileReceiveRequest
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud objectForKey:@"Preferences.Sound.file_receive_request"];
}

+ (NSString*)soundFileReceiveSuccess
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud objectForKey:@"Preferences.Sound.file_receive_success"];
}

+ (NSString*)soundFileSendFailure
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud objectForKey:@"Preferences.Sound.file_send_failure"];
}

+ (NSString*)soundFileSendSuccess
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud objectForKey:@"Preferences.Sound.file_send_success"];
}

+ (NSString*)soundHighlight
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud objectForKey:@"Preferences.Sound.highlight"];
}

+ (NSString*)soundInvited
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud objectForKey:@"Preferences.Sound.invited"];
}

+ (NSString*)soundKicked
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud objectForKey:@"Preferences.Sound.kicked"];
}

+ (NSString*)soundLogin
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud objectForKey:@"Preferences.Sound.login"];
}

+ (NSString*)soundNewtalk
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud objectForKey:@"Preferences.Sound.newtalk"];
}

+ (NSString*)soundTalktext
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	return [ud objectForKey:@"Preferences.Sound.talktext"];
}

+ (NSString*)themeLogFontName
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.Theme.log_font_name"];
	if (!obj) return @"Lucida Grande";
	return [obj objectValue];
}

+ (double)themeLogFontSize
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.Theme.log_font_size"];
	if (!obj) return 12;
	return [obj doubleValue];
}

+ (NSString*)themeName
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.Theme.name"];
	if (!obj) return @"resource:Default";
	return [obj objectValue];
}

+ (NSString*)themeNickFormat
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.Theme.nick_format"];
	if (!obj) return @"%n: ";
	return [obj objectValue];
}

+ (BOOL)themeOverrideLogFont
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.Theme.override_log_font"];
	if (!obj) return NO;
	return [obj boolValue];
}

+ (BOOL)themeOverrideNickFormat
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.Theme.override_nick_format"];
	if (!obj) return NO;
	return [obj boolValue];
}

+ (BOOL)themeOverrideTimestampFormat
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.Theme.override_timestamp_format"];
	if (!obj) return NO;
	return [obj boolValue];
}

+ (NSString*)themeTimestampFormat
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.Theme.timestamp_format"];
	if (!obj) return @"%H:%M";
	return [obj objectValue];
}

+ (double)themeTransparency
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id obj = [ud objectForKey:@"Preferences.Theme.transparency"];
	if (!obj) return 1;
	return [obj doubleValue];
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


+ (void)migrate
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	int version = [ud integerForKey:@"version"];
	
	if (version == 0) {
		// migrate string arrays
		
		NSString* oldKey;
		NSString* newKey;
		NSArray* ary;
		
		oldKey = @"Preferences.Keyword.words";
		newKey = @"keywords";
		ary = [ud objectForKey:oldKey];
		if (ary) {
			NSMutableArray* result = [NSMutableArray array];
			for (NSString* s in ary) {
				[result addObject:[NSMutableDictionary dictionaryWithObject:s forKey:@"string"]];
			}
			[ud setObject:result forKey:newKey];
			[ud removeObjectForKey:oldKey];
		}
		
		oldKey = @"Preferences.Keyword.dislike_words";
		newKey = @"excludeWords";
		ary = [ud objectForKey:oldKey];
		if (ary) {
			NSMutableArray* result = [NSMutableArray array];
			for (NSString* s in ary) {
				[result addObject:[NSMutableDictionary dictionaryWithObject:s forKey:@"string"]];
			}
			[ud setObject:result forKey:newKey];
			[ud removeObjectForKey:oldKey];
		}
		
		oldKey = @"Preferences.Keyword.ignore_words";
		newKey = @"ignoreWords";
		ary = [ud objectForKey:oldKey];
		if (ary) {
			NSMutableArray* result = [NSMutableArray array];
			for (NSString* s in ary) {
				[result addObject:[NSMutableDictionary dictionaryWithObject:s forKey:@"string"]];
			}
			[ud setObject:result forKey:newKey];
			[ud removeObjectForKey:oldKey];
		}
		
		[ud setInteger:1 forKey:@"version"];
		[ud synchronize];
	}
}

@end
