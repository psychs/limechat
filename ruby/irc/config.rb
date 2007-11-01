# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

module AutoOpMatchable
  def match_autoop(mask)
    @autoop.each do |i|
      return true if Wildcard.new(i) =~ mask
    end
    false
  end
end


class IRCWorldConfig
  include AutoOpMatchable
  attr_accessor :units
  attr_accessor :autoop
  
  def initialize(seed={})
    @units = []
    @autoop = []
    
    return unless seed
    seed.each do |k,v|
      next if k == :units
      instance_variable_set("@#{k.to_s}", v) if v != nil
    end
    unitary = seed[:units]
    if unitary
      unitary.each {|u| @units << IRCUnitConfig.new(u) }
    end
  end
  
  def to_dic
    h = {}
    instance_variables.each do |v|
      next if v == '@units'
      h[v[1..-1].to_sym] = instance_variable_get(v)
    end
    h
  end
  
  def to_s
    s = "=World\n"
    @units.each {|i| s += i.to_s }
    s
  end
  
  def dup
    Marshal::load(Marshal::dump(self))
  end
end


class IRCUnitConfig
  include AutoOpMatchable
  attr_accessor :name, :host, :port, :password, :nick, :username, :realname
  attr_accessor :auto_connect, :encoding
  attr_accessor :channels
  attr_accessor :leaving_comment, :userinfo, :invisible, :login_commands
  attr_accessor :autoop
  attr_accessor :owner, :id
  
  def initialize(seed={})
    @name = @host = @password = @nick = @username = @realname = ''
    @port = 6667
    @auto_connect = true
    @leaving_comment = 'Leaving...'
    @userinfo = ''
    @invisible = true
    @login_commands = []
    @channels = []
    @autoop = []
    
    defaults = OSX::NSUserDefaults.standardUserDefaults
    langs = defaults[:AppleLanguages]
    if langs && langs[0]
      @encoding = case langs[0].to_s
      when 'ja'; OSX::NSISO2022JPStringEncoding
      when 'ko'; -2147482590
      when 'zh-Hans'; -2147482063
      when 'zh-Hant'; -2147481085
      #when 'ru'; -2147481086
      else
        #OSX::NSISOLatin1StringEncoding
        OSX::NSUTF8StringEncoding
      end
    else
      @encoding = OSX::NSUTF8StringEncoding
    end
    
    seed.each do |k,v|
      next if k == :channels
      instance_variable_set("@#{k.to_s}", v) if v != nil
    end
    channelary = seed[:channels]
    if channelary
      channelary.each {|c| @channels << IRCChannelConfig.new(c) }
    end
  end
  
  def to_dic
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
      @cached_label = OSX::NSString.stringWithString(@name)
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
  attr_accessor :name, :password, :mode, :topic, :auto_join, :console, :keyword, :unread
  attr_reader :type
  attr_accessor :autoop
  attr_accessor :owner
  
  def initialize(seed={})
    @name = @password = @topic = ''
    @mode = '+sn'
    @auto_join = @console = @keyword = @unread = true
    @type = :channel
    @autoop = []
    
    seed.each do |k,v|
      instance_variable_set("@#{k.to_s}", v) if v != nil
    end
  end
  
  def to_dic
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
      @cached_label = OSX::NSString.stringWithString(@name)
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
        m.units = c.units.map do |i|
          i = config_to_item(i)
          i.owner = m
          i
        end
        m
      when IRCUnitConfig
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
        c.units = m.units.map {|i| item_to_config(i)}
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

class ModelTreeItemBase < OSX::NSObject
  attr_accessor :config, :owner
  
  def autoop
    @config.autoop
  end
  
  def name
    @config.name
  end
  
  def label
    if !@cached_label || !@cached_label.isEqualToString?(name)
      @cached_label = OSX::NSString.stringWithString(name)
    end
    @cached_label
  end
end

class WorldTreeItem < ModelTreeItemBase
  attr_accessor :units
  
  def name
    'World'
  end
end

class UnitTreeItem < ModelTreeItemBase
  attr_accessor :channels
  
  def id
    @config.id
  end
end

class ChannelTreeItem < ModelTreeItemBase
end
