s = <<EOM
Preferences.Dcc.action                          int     1
Preferences.Dcc.address_detection_method        int     2
Preferences.Dcc.first_port                      int     1096
Preferences.Dcc.last_port                       int     1115
Preferences.Dcc.myaddress                       string  @""

Preferences.General.auto_rejoin                 bool    NO
Preferences.General.confirm_quit                bool    YES
Preferences.General.connect_on_doubleclick      bool    NO
Preferences.General.disconnect_on_doubleclick   bool    NO
Preferences.General.hotkey_key_code             int     0
Preferences.General.hotkey_modifier_flags       int     0
Preferences.General.join_on_doubleclick         bool    NO
Preferences.General.leave_on_doubleclick        bool    NO
Preferences.General.log_transcript              bool    NO
Preferences.General.main_window_layout          int     0
Preferences.General.max_log_lines               int     300
Preferences.General.open_browser_in_background  bool    YES
Preferences.General.paste_command               string  @"privmsg"
Preferences.General.paste_syntax                string  [[[ud objectForKey:@"AppleLanguages"] objectAtIndex:0] isEqualToString:@"ja"] ? @"notice" : @"privmsg"
Preferences.General.show_inline_images          bool    YES
Preferences.General.show_join_leave             bool    YES
Preferences.General.stop_growl_on_active        bool    NO
Preferences.General.transcript_folder           string  @"~/Documents/LimeChat Transcripts"
Preferences.General.tab_action                  int     0
Preferences.General.use_growl                   bool    YES
Preferences.General.use_hotkey                  bool    NO

Preferences.Keyword.current_nick                bool    YES
Preferences.Keyword.dislike_words               array
Preferences.Keyword.ignore_words                array
Preferences.Keyword.matching_method             int     0
Preferences.Keyword.whole_line                  bool    NO
Preferences.Keyword.words                       array

Preferences.Sound.channeltext                   string
Preferences.Sound.disconnect                    string
Preferences.Sound.file_receive_failure          string
Preferences.Sound.file_receive_request          string
Preferences.Sound.file_receive_success          string
Preferences.Sound.file_send_failure             string
Preferences.Sound.file_send_success             string
Preferences.Sound.highlight                     string
Preferences.Sound.invited                       string
Preferences.Sound.kicked                        string
Preferences.Sound.login                         string
Preferences.Sound.newtalk                       string
Preferences.Sound.talktext                      string

Preferences.Theme.log_font_name                 string  @"Lucida Grande"
Preferences.Theme.log_font_size                 double  12
Preferences.Theme.name                          string  @"resource:Default"
Preferences.Theme.nick_format                   string  @"%n: "
Preferences.Theme.override_log_font             bool    NO
Preferences.Theme.override_nick_format          bool    NO
Preferences.Theme.override_timestamp_format     bool    NO
Preferences.Theme.timestamp_format              string  @"%H:%M"
Preferences.Theme.transparency                  double  1
EOM

TYPE_NAME_MAP = {
  'bool' => 'BOOL',
  'int' => 'int',
  'double' => 'double',
  'array' => 'NSArray*',
  'string' => 'NSString*',
}

OBJC_TYPE_MAP = {
  'bool' => 'bool',
  'int' => 'int',
  'double' => 'double',
  'array' => 'object',
  'string' => 'object',
}


header = []
source = []


s.each_line do |line|
  if m = /^([a-z_\.]+)\s+([a-z]+)(?:\s+(.+))?$/i.match(line)
    key = m[1]
    type_name = m[2]
    default_value = m[3]
    type = TYPE_NAME_MAP[type_name]
    objc_type = OBJC_TYPE_MAP[type_name]
    
    if m = /^[a-z]+\.([a-z]+)\.([a-z0-9_]+)$/i.match(key)
      category = m[1]
      name = m[2]
      ary = name.split(/_/)
      
      if category != 'General'
        ary = ary.insert(0, category.downcase)
      end
      
      camel = (ary[0..0] + ary[1..-1].map {|e| e.capitalize }).join
      capital = ary.map {|e| e.capitalize }.join
      
      if m = /^sound/i.match(camel)
        h =
<<EOM
+ (#{type})#{camel};
+ (void)set#{capital}:(#{type})value;
EOM
        header << h
      else
        h =
<<EOM
+ (#{type})#{camel};
EOM
        header << h
      end

      if default_value
        if objc_type == 'object'
          l =
<<EOM
+ (#{type})#{camel}
{
  NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
  id obj = [ud objectForKey:@"#{key}"];
  if (!obj) return #{default_value};
  return obj;
}

EOM
        else
          l =
<<EOM
+ (#{type})#{camel}
{
  NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
  id obj = [ud objectForKey:@"#{key}"];
  if (!obj) return #{default_value};
  return [obj #{objc_type}Value];
}

EOM
        end
      else
        l =
<<EOM
+ (#{type})#{camel}
{
  NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
  return [ud #{objc_type}ForKey:@"#{key}"];
}

EOM
      end
      
      source << l

      if m = /^sound/i.match(camel)
        l =
<<EOM
+ (void)set#{capital}:(#{type})value
{
  NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
  [ud set#{objc_type.capitalize}:value forKey:@"#{key}"];
}

EOM

        source << l
      end
    end
  end
end

header.each do |line|
  puts line
end

puts '========'

source.each do |line|
  puts line
end
