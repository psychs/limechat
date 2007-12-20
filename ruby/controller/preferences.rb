# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'userdefaultsaccess'
require 'persistencehelper'

class Preferences
  include UserDefaultsAccess
  
  class << self
    attr_reader :models
    def model_attr(*args)
      @models ||= []
      @models += args
      attr_reader(*args)
    end
  end
  
  class Keyword
    include PersistenceHelper
    persistent_attr :words, :dislike_words, :whole_line, :current_nick
    
    def initialize
      @words = []
      @dislike_words = []
      @whole_line = false
      @current_nick = true
    end
  end
  
  class Dcc
    include PersistenceHelper
    persistent_attr :first_port, :last_port, :address_detection_method, :myaddress
    
    ADDR_DETECT_JOIN = 0
    ADDR_DETECT_NIC = 1
    ADDR_DETECT_SPECIFY = 2
    
    def initialize
      @first_port = 1096
      @last_port = 1115
      @address_detection_method = ADDR_DETECT_JOIN
      @myaddress = ''
    end
  end
  
  class General
    include PersistenceHelper
    persistent_attr :confirm_quit
    persistent_attr :tab_action
    persistent_attr :main_window_layout
    persistent_attr :connect_on_doubleclick, :disconnect_on_doubleclick, :join_on_doubleclick, :leave_on_doubleclick
    persistent_attr :use_growl
    persistent_attr :log_transcript, :transcript_folder, :max_log_lines
    persistent_attr :paste_syntax
    
    TAB_COMPLETE_NICK = 0
    TAB_UNREAD = 1
    TAB_NONE = 100
    
    LAYOUT_2_COLUMNS = 0
    LAYOUT_3_COLUMNS = 1

    def initialize
      @confirm_quit = true
      @tab_action = TAB_COMPLETE_NICK
      @main_window_layout = LAYOUT_2_COLUMNS
      @connect_on_doubleclick = false
      @disconnect_on_doubleclick = false
      @join_on_doubleclick = true
      @leave_on_doubleclick = false
      @use_growl = true
      @log_transcript = false
      @transcript_folder = '~/Documents/LimeChatTranscripts'
      @max_log_lines = 300
      if LanguageSupport.primary_language == 'ja'
        @paste_syntax = 'notice'
      else
        @paste_syntax = 'privmsg'
      end
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
    persistent_attr :name, :override_log_font, :log_font_name, :log_font_size, :override_nick_format, :nick_format
    
    def initialize
      @name = 'resource:Default'
      @override_log_font = false
      @log_font_name = 'Lucida Grande'
      @log_font_size = 12
      @override_nick_format = false
      @nick_format = '(%n) '
    end
  end
  
  model_attr :key, :dcc, :gen, :sound, :theme
  
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
end
