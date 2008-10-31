# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'userdefaultsaccess'
require 'persistencehelper'
require 'utility'

class Preferences
  include UserDefaultsAccess
  
  class AbstractPreferencesSection
    class << self
      def section_defaults_key
        @section_defaults_key ||= name.sub(/Preferences::/, '').to_sym
      end
      
      def section_default_values
        Preferences.default_values[section_defaults_key] ||= {}
      end
      
      def defaults_accessor(name, default_value)
        section_default_values[name] = default_value
        
        class_eval do
          define_method(name) do
            section_user_defaults[name].to_ruby
          end
          
          define_method("#{name}=") do |value|
            defaults = section_user_defaults.to_ruby
            defaults[name] = value
            self.section_user_defaults = defaults
            value
          end
        end
      end
    end
    
    def section_user_defaults
      NSUserDefaults.standardUserDefaults[:pref][self.class.section_defaults_key]
    end
    
    def section_user_defaults=(section_user_defaults)
      defaults = NSUserDefaults.standardUserDefaults[:pref].to_ruby.merge(self.class.section_defaults_key => section_user_defaults)
      NSUserDefaults.standardUserDefaults.setObject_forKey(defaults, :pref)
    end
  end
  
  class << self
    attr_reader :models
    def model_attr(*args)
      @models ||= []
      @models += args
      attr_reader(*args)
    end
    
    def default_values
      @default_values ||= {}
    end
    
    def register_default_values!
      NSUserDefaults.standardUserDefaults.registerDefaults(:pref => default_values)
    end
  end
  
  class Keyword
    include PersistenceHelper
    persistent_attr :words, :dislike_words, :whole_line, :current_nick, :matching_method
    
    MATCH_PARTIAL = 0
    MATCH_EXACT_WORD = 1
    
    def initialize
      @words = []
      @dislike_words = []
      @whole_line = false
      @current_nick = true
      @matching_method = MATCH_PARTIAL
    end
  end
  
  class Dcc
    include PersistenceHelper
    persistent_attr :first_port, :last_port, :address_detection_method, :myaddress, :auto_receive
    
    ADDR_DETECT_JOIN = 0
    ADDR_DETECT_NIC = 1
    ADDR_DETECT_SPECIFY = 2
    
    def initialize
      @first_port = 1096
      @last_port = 1115
      @address_detection_method = ADDR_DETECT_JOIN
      @myaddress = ''
      @auto_receive = false
    end
  end
  
  class General < AbstractPreferencesSection
    TAB_COMPLETE_NICK = 0
    TAB_UNREAD = 1
    TAB_NONE = 100
    
    LAYOUT_2_COLUMNS = 0
    LAYOUT_3_COLUMNS = 1
    
    defaults_accessor :confirm_quit, true
    defaults_accessor :tab_action, TAB_COMPLETE_NICK
    
    defaults_accessor :use_hotkey, false
    defaults_accessor :hotkey_key_code, 0
    defaults_accessor :hotkey_modifier_flags, 0
    
    defaults_accessor :main_window_layout, LAYOUT_2_COLUMNS
    
    defaults_accessor :connect_on_doubleclick, false
    defaults_accessor :disconnect_on_doubleclick, false
    defaults_accessor :join_on_doubleclick, true
    defaults_accessor :leave_on_doubleclick, false
    
    defaults_accessor :use_growl, true
    defaults_accessor :stop_growl_on_active, true
    
    defaults_accessor :log_transcript, false
    defaults_accessor :transcript_folder, '~/Documents/LimeChat Transcripts'
    defaults_accessor :max_log_lines, 300
    
    defaults_accessor :paste_syntax, (LanguageSupport.primary_language == 'ja' ? 'notice' : 'privmsg')
    
    #include PersistenceHelper
    def set_persistent_attrs(*args)
    end
  end
  
  class Sound
    include PersistenceHelper
    persistent_attr :login, :disconnect, :highlight, :newtalk, :kicked, :invited, :channeltext, :talktext
    persistent_attr :file_receive_request, :file_receive_success, :file_receive_failure, :file_send_success, :file_send_failure
    
    def initialize
      @login = @disconnect = @highlight = @newtalk = @kicked = @invited = @channeltext = @talktext = ''
      @file_receive_request = @file_receive_success = @file_receive_failure = ''
      @file_send_success = @file_send_failure = ''
    end
  end
  
  class Theme
    include PersistenceHelper
    persistent_attr :name, :override_log_font, :log_font_name, :log_font_size, :override_nick_format, :nick_format, :override_timestamp_format, :timestamp_format
    
    def initialize
      @name = 'resource:Default'
      @override_log_font = false
      @log_font_name = 'Lucida Grande'
      @log_font_size = 12
      @override_nick_format = false
      @nick_format = '%n: '
      @override_timestamp_format = false
      @timestamp_format = '%H:%M'
    end
  end
  
  model_attr :key, :dcc, :gen, :sound, :theme
  
  # TODO: For now alias these, but should replace them completely
  alias_method :general, :gen
  
  def initialize
    @key = Keyword.new
    @dcc = Dcc.new
    @gen = General.new
    @sound = Sound.new
    @theme = Theme.new
    
    load
  end
    
  def load
    d = read_defaults('pref')
    if d
      self.class.models.each do |i|
        m = instance_variable_get("@#{i}")
        m.set_persistent_attrs(d[i])
      end
    else
      self.class.models.each do |i|
        m = instance_variable_get("@#{i}")
        d = read_defaults(i.to_s)
        m.set_persistent_attrs(d)
      end
    end
  end
  
  def save
    h = {}
    self.class.models.each do |i|
      m = instance_variable_get("@#{i}")
      h[i] = m.get_persistent_attrs
    end
    write_defaults('pref', h)
    sync
  end
  
  def load_world
    read_defaults('world')
  end
  
  def save_world(c)
    write_defaults('world', c)
    sync
  end
  
  def load_window(key)
    read_defaults(key)
  end
  
  def save_window(key, value)
    write_defaults(key, value)
    sync
  end
  
  private
  
  def sync
    NSUserDefaults.standardUserDefaults.synchronize
  end
  
  # And register the defaults
  register_default_values!
end
