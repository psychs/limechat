# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'userdefaultsaccess'
require 'persistencehelper'

class Preferences
  include OSX
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
    persistent_attr :words, :dislike_words
    
    def initialize
      @words = []
      @dislike_words = []
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
    persistent_attr :connect_on_doubleclick, :disconnect_on_doubleclick, :join_on_doubleclick, :leave_on_doubleclick
    persistent_attr :use_growl
    
    TAB_COMPLETE_NICK = 0
    TAB_UNREAD = 1
    TAB_NONE = 100

    def initialize
      @confirm_quit = true
      @tab_action = TAB_UNREAD
      @connect_on_doubleclick = false
      @disconnect_on_doubleclick = false
      @join_on_doubleclick = true
      @leave_on_doubleclick = false
      @use_growl = true
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
  
  model_attr :key, :dcc, :gen, :sound
  
  def initialize
    @key = Keyword.new
    @dcc = Dcc.new
    @gen = General.new
    @sound = Sound.new
  end
    
  def load
    d = read_defaults('pref')
    if d
      self.class.models.each do |i|
        m = instance_variable_get('@' + i.to_s)
        m.set_persistent_attrs(d[i])
      end
    else
      self.class.models.each do |i|
        m = instance_variable_get('@' + i.to_s)
        d = read_defaults(i.to_s)
        m.set_persistent_attrs(d)
      end
    end

    # workaround for the NSPopupButton problem
    v = @dcc.address_detection_method
    if v == true || v == false
      @dcc.address_detection_method = v ? 2 : 0
      save
    end
  end
  
  def save
    h = {}
    self.class.models.each do |i|
      m = instance_variable_get('@' + i.to_s)
      h[i] = m.get_persistent_attrs
    end
    write_defaults('pref', h)
  end
  
  def load_world
    d = read_defaults('world')
    return nil unless d
    
    # workaround for the NSPopupButton problem
    collect = false
    units = d[:units]
    units.each do |i|
      v = i[:encoding]
      if v == true || v == false
        c = IRCUnitConfig.new
        i[:encoding] = c.encoding
        collect = true
      end
    end
    if collect
      save_world(d)
    end
    
    d
  end
  
  def save_world(c)
    write_defaults('world', c)
  end
  
  def load_window(key)
    read_defaults(key)
  end
  
  def save_window(key, value)
    write_defaults(key, value)
  end
  
  def sync
    NSUserDefaults.standardUserDefaults.synchronize
  end
end
