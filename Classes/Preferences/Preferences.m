// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "Preferences.h"
#import "NSLocaleHelper.h"
#import "NSDictionaryHelper.h"


static NSMutableArray* keywords;
static NSMutableArray* excludeWords;


@implementation Preferences

+ (DCCActionType)dccAction
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    return [ud integerForKey:@"Preferences.Dcc.action"];
}

+ (AddressDetectionType)dccAddressDetectionMethod
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    return [ud integerForKey:@"Preferences.Dcc.address_detection_method"];
}

+ (NSString*)dccMyaddress
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    return [ud objectForKey:@"Preferences.Dcc.myaddress"];
}

+ (BOOL)autoRejoin
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    return [ud boolForKey:@"Preferences.General.auto_rejoin"];
}

+ (BOOL)confirmQuit
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    return [ud boolForKey:@"Preferences.General.confirm_quit"];
}

+ (DoubleClickUserActionType)doubleClickUserAction
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    return [ud integerForKey:@"Preferences.General.doubleClickUser"];
}

+ (BOOL)connectOnDoubleclick
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    return [ud boolForKey:@"Preferences.General.connect_on_doubleclick"];
}

+ (BOOL)disconnectOnDoubleclick
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    return [ud boolForKey:@"Preferences.General.disconnect_on_doubleclick"];
}

+ (BOOL)joinOnDoubleclick
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    return [ud boolForKey:@"Preferences.General.join_on_doubleclick"];
}

+ (BOOL)leaveOnDoubleclick
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    return [ud boolForKey:@"Preferences.General.leave_on_doubleclick"];
}

+ (BOOL)logTranscript
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    return [ud boolForKey:@"Preferences.General.log_transcript"];
}

+ (MainWindowLayoutType)mainWindowLayout
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    return [ud integerForKey:@"Preferences.General.main_window_layout"];
}

+ (BOOL)openBrowserInBackground
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    return [ud boolForKey:@"Preferences.General.open_browser_in_background"];
}

+ (BOOL)showInlineImages
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    return [ud boolForKey:@"Preferences.General.show_inline_images"];
}

+ (BOOL)showJoinLeave
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    return [ud boolForKey:@"Preferences.General.show_join_leave"];
}

+ (BOOL)showModeChange
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    return [ud boolForKey:@"Preferences.General.show_mode_changes"];
}

+ (BOOL)showRename
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    return [ud boolForKey:@"Preferences.General.showRename"];
}

+ (BOOL)stopNotificationsOnActive
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    return [ud boolForKey:@"Preferences.General.stop_growl_on_active"];
}

+ (BOOL)bounceIconOnEveryPrivateMessage
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    return [ud boolForKey:@"Preferences.General.bounceIconOnEveryPrivateMessage"];
}

+ (BOOL)autoJoinOnInvited
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    return [ud boolForKey:@"Preferences.General.auto_join_on_invited"];
}


+ (TabActionType)tabAction
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    return [ud integerForKey:@"Preferences.General.tab_action"];
}

+ (BOOL)useHotkey
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    return [ud boolForKey:@"Preferences.General.use_hotkey"];
}

+ (BOOL)keywordCurrentNick
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    return [ud boolForKey:@"Preferences.Keyword.current_nick"];
}

+ (NSArray*)keywordDislikeWords
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    return [ud objectForKey:@"Preferences.Keyword.dislike_words"];
}

+ (KeywordMatchType)keywordMatchingMethod
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    return [ud integerForKey:@"Preferences.Keyword.matching_method"];
}

+ (BOOL)keywordWholeLine
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    return [ud boolForKey:@"Preferences.Keyword.whole_line"];
}

+ (NSArray*)keywordWords
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    return [ud objectForKey:@"Preferences.Keyword.words"];
}

#pragma mark - Paste

+ (NSString*)pasteCommand
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    return [ud objectForKey:@"Preferences.General.paste_command"];
}

+ (void)setPasteCommand:(NSString*)value
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    [ud setObject:value forKey:@"Preferences.General.paste_command"];
}

+ (NSString*)pasteSyntax
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    return [ud objectForKey:@"Preferences.General.paste_syntax"];
}

+ (void)setPasteSyntax:(NSString*)value
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    [ud setObject:value forKey:@"Preferences.General.paste_syntax"];
}

#pragma mark - Theme

+ (NSString*)themeName
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    return [ud objectForKey:@"Preferences.Theme.name"];
}

+ (void)setThemeName:(NSString*)value
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    [ud setObject:value forKey:@"Preferences.Theme.name"];
}

+ (NSString*)themeLogFontName
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    return [ud objectForKey:@"Preferences.Theme.log_font_name"];
}

+ (void)setThemeLogFontName:(NSString*)value
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    [ud setObject:value forKey:@"Preferences.Theme.log_font_name"];
}

+ (double)themeLogFontSize
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    return [ud doubleForKey:@"Preferences.Theme.log_font_size"];
}

+ (void)setThemeLogFontSize:(double)value
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    [ud setDouble:value forKey:@"Preferences.Theme.log_font_size"];
}

+ (NSString*)themeInputFontName
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    return [ud objectForKey:@"Preferences.Theme.input_font_name"];
}

+ (void)setThemeInputFontName:(NSString*)value
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    [ud setObject:value forKey:@"Preferences.Theme.input_font_name"];
}

+ (double)themeInputFontSize
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    return [ud doubleForKey:@"Preferences.Theme.input_font_size"];
}

+ (void)setThemeInputFontSize:(double)value
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    [ud setDouble:value forKey:@"Preferences.Theme.input_font_size"];
}

+ (NSString*)themeNickFormat
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    return [ud objectForKey:@"Preferences.Theme.nick_format"];
}

+ (BOOL)themeOverrideLogFont
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    return [ud boolForKey:@"Preferences.Theme.override_log_font"];
}

+ (BOOL)themeOverrideInputFont
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    return [ud boolForKey:@"Preferences.Theme.override_input_font"];
}

+ (BOOL)themeOverrideNickFormat
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    return [ud boolForKey:@"Preferences.Theme.override_nick_format"];
}

+ (BOOL)themeOverrideTimestampFormat
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    return [ud boolForKey:@"Preferences.Theme.override_timestamp_format"];
}

+ (NSString*)themeTimestampFormat
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    return [ud objectForKey:@"Preferences.Theme.timestamp_format"];
}

+ (double)themeTransparency
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    return [ud doubleForKey:@"Preferences.Theme.transparency"];
}

#pragma mark - DCC Ports

+ (int)dccFirstPort
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    return [ud integerForKey:@"Preferences.Dcc.first_port"];
}

+ (void)setDccFirstPort:(int)value
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    [ud setInteger:value forKey:@"Preferences.Dcc.first_port"];
}

+ (int)dccLastPort
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    return [ud integerForKey:@"Preferences.Dcc.last_port"];
}

+ (void)setDccLastPort:(int)value
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    [ud setInteger:value forKey:@"Preferences.Dcc.last_port"];
}

#pragma mark - Connectivity

+ (int)pongInterval
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    return [ud integerForKey:@"Preferences.Advanced.pongInterval"];
}

+ (void)setPongInterval:(int)value
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    [ud setInteger:value forKey:@"Preferences.Advanced.pongInterval"];
}

#pragma mark - Max Log Lines

+ (int)maxLogLines
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    return [ud integerForKey:@"Preferences.General.max_log_lines"];
}

+ (void)setMaxLogLines:(int)value
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    [ud setInteger:value forKey:@"Preferences.General.max_log_lines"];
}

#pragma mark - Transcript Folder

+ (NSString*)transcriptFolder
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    return [ud objectForKey:@"Preferences.General.transcript_folder"];
}

+ (void)setTranscriptFolder:(NSString*)value
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    [ud setObject:value forKey:@"Preferences.General.transcript_folder"];
}

#pragma mark - Events

+ (NSString*)titleForEvent:(UserNotificationType)event
{
    switch (event) {
        case USER_NOTIFICATION_HIGHLIGHT:
            return @"Highlight";
        case USER_NOTIFICATION_NEW_TALK:
            return @"New private message";
        case USER_NOTIFICATION_CHANNEL_MSG:
            return @"Channel message";
        case USER_NOTIFICATION_CHANNEL_NOTICE:
            return @"Channel notice";
        case USER_NOTIFICATION_TALK_MSG:
            return @"Private message";
        case USER_NOTIFICATION_TALK_NOTICE:
            return @"Private notice";
        case USER_NOTIFICATION_KICKED:
            return @"Kicked";
        case USER_NOTIFICATION_INVITED:
            return @"Invited";
        case USER_NOTIFICATION_LOGIN:
            return @"Logged in";
        case USER_NOTIFICATION_DISCONNECT:
            return @"Disconnected";
        case USER_NOTIFICATION_FILE_RECEIVE_REQUEST:
            return @"DCC file receive request";
        case USER_NOTIFICATION_FILE_RECEIVE_SUCCESS:
            return @"DCC file receive success";
        case USER_NOTIFICATION_FILE_RECEIVE_ERROR:
            return @"DCC file receive failure";
        case USER_NOTIFICATION_FILE_SEND_SUCCESS:
            return @"DCC file send success";
        case USER_NOTIFICATION_FILE_SEND_ERROR:
            return @"DCC file send failure";
        default:
            break;
    }

    return nil;
}

+ (NSString*)oldKeyForEvent:(UserNotificationType)event
{
    switch (event) {
        case USER_NOTIFICATION_HIGHLIGHT:
            return @"Preferences.Sound.highlight";
        case USER_NOTIFICATION_NEW_TALK:
            return @"Preferences.Sound.newtalk";
        case USER_NOTIFICATION_CHANNEL_MSG:
            return @"Preferences.Sound.channeltext";
        case USER_NOTIFICATION_CHANNEL_NOTICE:
            return @"channelNoticeSound";
        case USER_NOTIFICATION_TALK_MSG:
            return @"Preferences.Sound.talktext";
        case USER_NOTIFICATION_TALK_NOTICE:
            return @"talkNoticeSound";
        case USER_NOTIFICATION_KICKED:
            return @"Preferences.Sound.kicked";
        case USER_NOTIFICATION_INVITED:
            return @"Preferences.Sound.invited";
        case USER_NOTIFICATION_LOGIN:
            return @"Preferences.Sound.login";
        case USER_NOTIFICATION_DISCONNECT:
            return @"Preferences.Sound.disconnect";
        case USER_NOTIFICATION_FILE_RECEIVE_REQUEST:
            return @"Preferences.Sound.file_receive_request";
        case USER_NOTIFICATION_FILE_RECEIVE_SUCCESS:
            return @"Preferences.Sound.file_receive_success";
        case USER_NOTIFICATION_FILE_RECEIVE_ERROR:
            return @"Preferences.Sound.file_receive_failure";
        case USER_NOTIFICATION_FILE_SEND_SUCCESS:
            return @"Preferences.Sound.file_send_success";
        case USER_NOTIFICATION_FILE_SEND_ERROR:
            return @"Preferences.Sound.file_send_failure";
        default:
            break;
    }

    return nil;
}

+ (NSString*)keyForEvent:(UserNotificationType)event
{
    switch (event) {
        case USER_NOTIFICATION_HIGHLIGHT:
            return @"eventHighlight";
        case USER_NOTIFICATION_NEW_TALK:
            return @"eventNewtalk";
        case USER_NOTIFICATION_CHANNEL_MSG:
            return @"eventChannelText";
        case USER_NOTIFICATION_CHANNEL_NOTICE:
            return @"eventChannelNotice";
        case USER_NOTIFICATION_TALK_MSG:
            return @"eventTalkText";
        case USER_NOTIFICATION_TALK_NOTICE:
            return @"eventTalkNotice";
        case USER_NOTIFICATION_KICKED:
            return @"eventKicked";
        case USER_NOTIFICATION_INVITED:
            return @"eventInvited";
        case USER_NOTIFICATION_LOGIN:
            return @"eventLogin";
        case USER_NOTIFICATION_DISCONNECT:
            return @"eventDisconnect";
        case USER_NOTIFICATION_FILE_RECEIVE_REQUEST:
            return @"eventFileReceiveRequest";
        case USER_NOTIFICATION_FILE_RECEIVE_SUCCESS:
            return @"eventFileReceiveSuccess";
        case USER_NOTIFICATION_FILE_RECEIVE_ERROR:
            return @"eventFileReceiveFailure";
        case USER_NOTIFICATION_FILE_SEND_SUCCESS:
            return @"eventFileSendSuccess";
        case USER_NOTIFICATION_FILE_SEND_ERROR:
            return @"eventFileSendFailure";
        default:
            break;
    }

    return nil;
}

+ (NSString*)soundForEvent:(UserNotificationType)event
{
    NSString* key = [[self keyForEvent:event] stringByAppendingString:@"Sound"];
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    return [ud objectForKey:key];
}

+ (void)setSound:(NSString*)value forEvent:(UserNotificationType)event
{
    NSString* key = [[self keyForEvent:event] stringByAppendingString:@"Sound"];
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    [ud setObject:value forKey:key];
}

+ (BOOL)userNotificationEnabledForEvent:(UserNotificationType)event
{
    NSString* key = [[self keyForEvent:event] stringByAppendingString:@"Growl"];
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    return [ud boolForKey:key];
}

+ (void)setUserNotificationEnabled:(BOOL)value forEvent:(UserNotificationType)event
{
    NSString* key = [[self keyForEvent:event] stringByAppendingString:@"Growl"];
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    [ud setBool:value forKey:key];
}

#pragma mark - World

+ (BOOL)spellCheckEnabled
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    if (![ud objectForKey:@"spellCheck2"]) return YES;
    return [ud boolForKey:@"spellCheck2"];
}

+ (void)setSpellCheckEnabled:(BOOL)value
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    [ud setBool:value forKey:@"spellCheck2"];
}

+ (BOOL)grammarCheckEnabled
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    return [ud boolForKey:@"grammarCheck"];
}

+ (void)setGrammarCheckEnabled:(BOOL)value
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    [ud setBool:value forKey:@"grammarCheck"];
}

+ (BOOL)spellingCorrectionEnabled
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    return [ud boolForKey:@"spellingCorrection"];
}

+ (void)setSpellingCorrectionEnabled:(BOOL)value
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    [ud setBool:value forKey:@"spellingCorrection"];
}

+ (BOOL)smartInsertDeleteEnabled
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    if (![ud objectForKey:@"smartInsertDelete"]) return YES;
    return [ud boolForKey:@"smartInsertDelete"];
}

+ (void)setSmartInsertDeleteEnabled:(BOOL)value
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    [ud setBool:value forKey:@"smartInsertDelete"];
}

+ (BOOL)quoteSubstitutionEnabled
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    return [ud boolForKey:@"quoteSubstitution"];
}

+ (void)setQuoteSubstitutionEnabled:(BOOL)value
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    [ud setBool:value forKey:@"quoteSubstitution"];
}

+ (BOOL)dashSubstitutionEnabled
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    return [ud boolForKey:@"dashSubstitution"];
}

+ (void)setDashSubstitutionEnabled:(BOOL)value
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    [ud setBool:value forKey:@"dashSubstitution"];
}

+ (BOOL)linkDetectionEnabled
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    return [ud boolForKey:@"linkDetection"];
}

+ (void)setLinkDetectionEnabled:(BOOL)value
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    [ud setBool:value forKey:@"linkDetection"];
}

+ (BOOL)dataDetectionEnabled
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    return [ud boolForKey:@"dataDetection"];
}

+ (void)setDataDetectionEnabled:(BOOL)value
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    [ud setBool:value forKey:@"dataDetection"];
}

+ (BOOL)textReplacementEnabled
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    return [ud boolForKey:@"textReplacement"];
}

+ (void)setTextReplacementEnabled:(BOOL)value
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    [ud setBool:value forKey:@"textReplacement"];
}

#pragma mark - World

+ (NSDictionary*)loadWorld
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    return [ud objectForKey:@"world"];
}

+ (void)saveWorld:(NSDictionary*)value
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    [ud setObject:value forKey:@"world"];
}

#pragma mark - Window

+ (NSDictionary*)loadWindowStateWithName:(NSString*)name
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    return [ud objectForKey:name];
}

+ (void)saveWindowState:(NSDictionary*)value name:(NSString*)name
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    [ud setObject:value forKey:name];
}

#pragma mark - Hot Keys

+ (int)hotKeyKeyCode
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    return [ud integerForKey:@"Preferences.General.hotkey_key_code"];
}

+ (void)setHotKeyKeyCode:(int)value
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    [ud setInteger:value forKey:@"Preferences.General.hotkey_key_code"];
}

+ (NSUInteger)hotKeyModifierFlags
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    return [ud integerForKey:@"Preferences.General.hotkey_modifier_flags"];
}

+ (void)setHotKeyModifierFlags:(NSUInteger)value
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    [ud setInteger:value forKey:@"Preferences.General.hotkey_modifier_flags"];
}

#pragma mark - Keywords

+ (void)loadKeywords
{
    if (keywords) {
        [keywords removeAllObjects];
    }
    else {
        keywords = [NSMutableArray new];
    }

    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    NSArray* ary = [ud objectForKey:@"keywords"];
    for (NSDictionary* e in ary) {
        NSString* s = [e objectForKey:@"string"];
        if (s) [keywords addObject:s];
    }
}

+ (void)loadExcludeWords
{
    if (excludeWords) {
        [excludeWords removeAllObjects];
    }
    else {
        excludeWords = [NSMutableArray new];
    }

    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    NSArray* ary = [ud objectForKey:@"excludeWords"];
    for (NSDictionary* e in ary) {
        NSString* s = [e objectForKey:@"string"];
        if (s) [excludeWords addObject:s];
    }
}

+ (void)cleanUpWords:(NSString*)key
{
    //
    // load
    //
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    NSArray* src = [ud objectForKey:key];

    NSMutableArray* ary = [NSMutableArray array];
    for (NSDictionary* e in src) {
        NSString* s = [e objectForKey:@"string"];
        if (s.length) {
            [ary addObject:s];
        }
    }

    //
    // sort
    //
    [ary sortUsingSelector:@selector(caseInsensitiveCompare:)];

    //
    // save
    //
    NSMutableArray* saveAry = [NSMutableArray array];
    for (NSString* s in ary) {
        NSMutableDictionary* dic = [NSMutableDictionary dictionary];
        [dic setObject:s forKey:@"string"];
        [saveAry addObject:dic];
    }
    [ud setObject:saveAry forKey:key];
    [ud synchronize];
}

+ (void)cleanUpWords
{
    [self cleanUpWords:@"keywords"];
    [self cleanUpWords:@"excludeWords"];
}

+ (NSArray*)keywords
{
    return keywords;
}

+ (NSArray*)excludeWords
{
    return excludeWords;
}

#pragma mark - KVO

+ (void)observeValueForKeyPath:(NSString*)key ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([key isEqualToString:@"keywords"]) {
        [self loadKeywords];
    }
    else if ([key isEqualToString:@"excludeWords"]) {
        [self loadExcludeWords];
    }
}

+ (void)initPreferences
{
    NSMutableDictionary* d = [NSMutableDictionary dictionary];
    [d setInt:DCC_SHOW_DIALOG forKey:@"Preferences.Dcc.action"];
    [d setInt:ADDRESS_DETECT_JOIN forKey:@"Preferences.Dcc.address_detection_method"];
    [d setObject:@"" forKey:@"Preferences.Dcc.myaddress"];
    [d setBool:NO forKey:@"Preferences.General.auto_rejoin"];
    [d setBool:YES forKey:@"Preferences.General.confirm_quit"];
    [d setInt:DOUBLE_CLICK_USER_ACTION_TALK forKey:@"Preferences.General.doubleClickUser"];
    [d setBool:NO forKey:@"Preferences.General.connect_on_doubleclick"];
    [d setBool:NO forKey:@"Preferences.General.disconnect_on_doubleclick"];
    [d setBool:NO forKey:@"Preferences.General.join_on_doubleclick"];
    [d setBool:NO forKey:@"Preferences.General.leave_on_doubleclick"];
    [d setBool:NO forKey:@"Preferences.General.log_transcript"];
    [d setInt:MAIN_WINDOW_LAYOUT_2_COLUMN forKey:@"Preferences.General.main_window_layout"];
    [d setBool:YES forKey:@"Preferences.General.open_browser_in_background"];
    [d setBool:YES forKey:@"Preferences.General.show_inline_images"];
    [d setBool:YES forKey:@"Preferences.General.show_join_leave"];
    [d setBool:YES forKey:@"Preferences.General.show_mode_changes"];
    [d setBool:YES forKey:@"Preferences.General.showRename"];
    [d setBool:YES forKey:@"Preferences.General.use_growl"];
    [d setBool:YES forKey:@"Preferences.General.stop_growl_on_active"];
    [d setBool:YES forKey:@"Preferences.General.bounceIconOnEveryPrivateMessage"];
    [d setBool:YES forKey:@"eventHighlightGrowl"];
    [d setBool:YES forKey:@"eventNewtalkGrowl"];
    [d setBool:YES forKey:@"eventInvitedGrowl"];
    [d setInt:TAB_COMPLETE_NICK forKey:@"Preferences.General.tab_action"];
    [d setBool:NO forKey:@"Preferences.General.use_hotkey"];
    [d setBool:YES forKey:@"Preferences.Keyword.current_nick"];
    [d setInt:KEYWORD_MATCH_PARTIAL forKey:@"Preferences.Keyword.matching_method"];
    [d setBool:NO forKey:@"Preferences.Keyword.whole_line"];
    [d setObject:@"privmsg" forKey:@"Preferences.General.paste_command"];
    [d setObject:@"plain text" forKey:@"Preferences.General.paste_syntax"];
    [d setObject:@"resource:Limelight" forKey:@"Preferences.Theme.name"];
    [d setObject:@"Lucida Grande" forKey:@"Preferences.Theme.log_font_name"];
    [d setDouble:12 forKey:@"Preferences.Theme.log_font_size"];
    [d setObject:@"Lucida Grande" forKey:@"Preferences.Theme.input_font_name"];
    [d setDouble:12 forKey:@"Preferences.Theme.input_font_size"];
    [d setObject:@"%n: " forKey:@"Preferences.Theme.nick_format"];
    [d setBool:NO forKey:@"Preferences.Theme.override_log_font"];
    [d setBool:NO forKey:@"Preferences.Theme.override_input_font"];
    [d setBool:NO forKey:@"Preferences.Theme.override_nick_format"];
    [d setBool:NO forKey:@"Preferences.Theme.override_timestamp_format"];
    [d setObject:@"%H:%M" forKey:@"Preferences.Theme.timestamp_format"];
    [d setDouble:1 forKey:@"Preferences.Theme.transparency"];
    [d setInt:1096 forKey:@"Preferences.Dcc.first_port"];
    [d setInt:1115 forKey:@"Preferences.Dcc.last_port"];
    [d setInt:60 forKey:@"Preferences.Advanced.pongInterval"];
    [d setInt:300 forKey:@"Preferences.General.max_log_lines"];
    [d setObject:@"~/Documents/LimeChat Transcripts" forKey:@"Preferences.General.transcript_folder"];
    [d setInt:0 forKey:@"Preferences.General.hotkey_key_code"];
    [d setInt:0 forKey:@"Preferences.General.hotkey_modifier_flags"];

    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    [ud registerDefaults:d];
    [ud addObserver:(NSObject*)self forKeyPath:@"keywords" options:NSKeyValueObservingOptionNew context:NULL];
    [ud addObserver:(NSObject*)self forKeyPath:@"excludeWords" options:NSKeyValueObservingOptionNew context:NULL];

    [self loadKeywords];
    [self loadExcludeWords];
}

#pragma mark - Migration

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
    }

    if (version <= 1) {
        // migrate sounds

        NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];

        for (int i=0; i<USER_NOTIFICATION_COUNT; ++i) {
            NSString* oldKey = [Preferences oldKeyForEvent:i];
            NSString* s = [ud objectForKey:oldKey];
            if (s.length) {
                [Preferences setSound:s forEvent:i];
            }
        }
    }

    if (version <= 2) {
        // set double click action in user list

        if ([NSLocale prefersJapaneseLanguage]) {
            [ud setInteger:DOUBLE_CLICK_USER_ACTION_WHOIS forKey:@"Preferences.General.doubleClickUser"];
        }
        else {
            [ud setInteger:DOUBLE_CLICK_USER_ACTION_TALK forKey:@"Preferences.General.doubleClickUser"];
        }

        [ud setInteger:3 forKey:@"version"];
        [ud synchronize];
    }
}

+ (void)sync
{
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
