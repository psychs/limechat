# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'utility'

module AutoOpMatchable
  def match_autoop(mask)
    @autoop.each do |i|
      return true if Wildcard.new(i, Regexp::IGNORECASE) =~ mask
    end
    false
  end
end

class IRCWorldConfig
  include AutoOpMatchable
  attr_accessor :clients
  attr_accessor :autoop
  
  def initialize(seed={})
    @clients = []
    @autoop = []
    
    return unless seed
    seed.each do |k,v|
      next if k == :clients || k == :units
      instance_variable_set("@#{k}", v) if v != nil
    end

    if ary = seed[:clients] || seed[:units]
      ary.each {|u| @clients << IRCClientConfig.new(u) }
    end
  end
  
  def dictionaryValue
    h = {}
    instance_variables.each do |v|
      next if v == '@clients'
      h[v[1..-1].to_sym] = instance_variable_get(v)
    end
    h
  end
  
  def to_s
    s = "=World\n"
    @clients.each {|i| s += i.to_s }
    s
  end
  
  def dup
    Marshal::load(Marshal::dump(self))
  end
end


class IRCClientConfig
  include AutoOpMatchable
  attr_accessor :name, :host, :port, :password, :nick, :alt_nicks, :username, :realname, :nickPassword
  attr_accessor :ssl, :auto_connect, :encoding, :fallback_encoding
  attr_accessor :proxy, :proxy_host, :proxy_port, :proxy_user, :proxy_password
  attr_accessor :channels
  attr_accessor :leaving_comment, :userinfo, :invisible, :login_commands
  attr_accessor :autoop
  attr_accessor :owner, :uid
  
  PROXY_NONE = 0
  PROXY_SOCKS4 = 4
  PROXY_SOCKS5 = 5
  PROXY_SOCKS_SYSTEM = 1
  
  
  def initialize(seed={})
    @name = @host = @password = @nick = @username = @realname = @nickPassword = ''
    @alt_nicks = []
    @port = 6667
    @ssl = false
    @proxy = PROXY_NONE
    @proxy_host = @proxy_user = @proxy_password = ''
    @proxy_port = 1080
    @auto_connect = true
    @leaving_comment = 'Leaving...'
    @userinfo = ''
    @invisible = true
    @login_commands = []
    @channels = []
    @autoop = []
    
    @fallback_encoding = NSUTF8StringEncoding
    
    case LanguageSupport.primary_language
    when 'ja'
      @encoding = NSISO2022JPStringEncoding
    when 'ko'
      @encoding = NSLCCP949StringEncoding
    when 'zh-Hans'
      @encoding = NSLCGBKStringEncoding
    when 'zh-Hant'
      @encoding = NSLCBIG5StringEncoding
    else
      @encoding = NSUTF8StringEncoding
      @fallback_encoding = NSISOLatin1StringEncoding
    end
    
    seed.each do |k,v|
      next if k == :channels
      instance_variable_set("@#{k}", v) if v != nil
    end
    channelary = seed[:channels]
    if channelary
      channelary.each {|c| @channels << IRCChannelConfig.new(c) }
    end
  end
  
  def dictionaryValue
    h = {}
    instance_variables.each do |v|
      next if v == '@channels'
      next if v == '@cached_label'
      h[v[1..-1].to_sym] = instance_variable_get(v)
    end
    h
  end
  
  def label
    if !@cached_label || !@cached_label.isEqualToString?(@name)
      @cached_label = @name.to_ns
    end
    @cached_label
  end
  
  def to_s
    s = "  =Unit\n"
    instance_variables.each do |i|
      next if i == '@channels'
      s += "    #{i} = #{instance_variable_get(i)}\n"
    end
    @channels.each {|i| s += i.to_s }
    s
  end
  
  def dup
    Marshal::load(Marshal::dump(self))
  end
end


class IRCChannelConfig
  include AutoOpMatchable
  attr_accessor :name, :password, :mode, :topic, :auto_join, :console, :keyword, :unread, :growl
  attr_reader :type
  attr_accessor :autoop
  attr_accessor :owner
  
  def initialize(seed={})
    @name = @password = @topic = ''
    @mode = '+sn'
    @auto_join = @console = @keyword = @unread = @growl = true
    @type = :channel
    @autoop = []
    
    seed.each do |k,v|
      instance_variable_set("@#{k}", v) if v != nil
    end
  end
  
  def dictionaryValue
    h = {}
    instance_variables.each do |v|
      next if v == '@type'
      next if v == '@cached_label'
      h[v[1..-1].to_sym] = instance_variable_get(v)
    end
    h
  end
  
  def label
    if !@cached_label || !@cached_label.isEqualToString?(@name)
      @cached_label = @name.to_ns
    end
    @cached_label
  end
  
  def to_s
    s = "    =Channel\n"
    instance_variables.each {|i| s += "      #{i} = #{instance_variable_get(i)}\n" }
    s
  end
  
  def dup
    Marshal::load(Marshal::dump(self))
  end
end


module ModelTreeItem
  def config_to_item(c)
    case c
      when IRCWorldConfig
        m = WorldTreeItem.alloc.init
        m.config = c
        m.clients = c.clients.map do |i|
          i = config_to_item(i)
          i.owner = m
          i
        end
        m
      when IRCClientConfig
        m = UnitTreeItem.alloc.init
        m.config = c
        m.channels = c.channels.map do |i|
          i = config_to_item(i)
          i.owner = m
          i
        end
        m
      when IRCChannelConfig
        m = ChannelTreeItem.alloc.init
        m.config = c
        m
    end
  end
  
  def item_to_config(m)
    case m
      when WorldTreeItem
        c = m.config
        c.clients = m.clients.map {|i| item_to_config(i)}
        c
      when UnitTreeItem
        c = m.config
        c.channels = m.channels.map {|i| item_to_config(i)}
        c
      when ChannelTreeItem
        m.config
    end
  end
  
  extend self
end

class ModelTreeItemBase < NSObject
  attr_accessor :config, :owner
  
  def autoop
    @config.autoop
  end
  
  def name
    @config.name
  end
  
  def label
    if !@cached_label || !@cached_label.isEqualToString?(name)
      @cached_label = name.to_ns
    end
    @cached_label
  end
end

class WorldTreeItem < ModelTreeItemBase
  attr_accessor :clients
  
  def name
    'World'
  end
end

class UnitTreeItem < ModelTreeItemBase
  attr_accessor :channels
  
  def uid
    @config.uid
  end
end

class ChannelTreeItem < ModelTreeItemBase
end
