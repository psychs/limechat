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
    langs = defaults['AppleLanguages']
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
      h[v[1..-1].to_sym] = instance_variable_get(v)
    end
    h
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
      h[v[1..-1].to_sym] = instance_variable_get(v)
    end
    h
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
