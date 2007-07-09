# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

class IRCWorldConfig
  attr_accessor :units
  
  def initialize(seed={})
    @units = []
    return unless seed
    seed.each do |k,v|
      next if k == :units
      self.instance_variable_set("@#{k.to_s}", v) if v != nil
    end
    unitary = seed[:units]
    if unitary
      unitary.each {|u| @units << IRCUnitConfig.new(u) }
    end
  end
  
  def to_dic
    h = {}
    self.instance_variables.each do |v|
      next if v == '@units'
      h[v[1..-1].to_sym] = self.instance_variable_get(v)
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
  attr_accessor :name, :host, :port, :password, :nick, :username, :realname
  attr_accessor :auto_connect, :encoding
  attr_accessor :channels
  attr_accessor :leaving_comment, :userinfo, :invisible
  
  def initialize(seed={})
    @name = @host = @password = @nick = @username = @realname = ''
    @port = 6667
    @auto_connect = true
    @leaving_comment = 'Leaving...'
    @userinfo = ''
    @invisible = true
    @channels = []
    
    defaults = OSX::NSUserDefaults.standardUserDefaults
    langs = defaults['AppleLanguages']
    if langs && langs[0] && langs[0].to_s == 'ja'
      @encoding = OSX::NSISO2022JPStringEncoding
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
    self.instance_variables.each do |v|
      next if v == '@channels'
      h[v[1..-1].to_sym] = self.instance_variable_get(v)
    end
    h
  end
  
  def to_s
    s = "  =Unit\n"
    self.instance_variables.each do |i|
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
  attr_accessor :name, :password, :mode, :topic, :auto_join, :console, :keyword, :unread
  attr_reader :type
  
  def initialize(seed={})
    @name = @password = @topic = ''
    @mode = '+sn'
    @auto_join = @console = @keyword = @unread = true
    @type = :channel
    seed.each do |k,v|
      self.instance_variable_set("@#{k.to_s}", v) if v != nil
    end
  end
  
  def to_dic
    h = {}
    instance_variables.each do |v|
      next if v == '@type'
      h[v[1..-1].to_sym] = self.instance_variable_get(v)
    end
    h
  end
  
  def to_s
    s = "    =Channel\n"
    self.instance_variables.each {|i| s += "      #{i} = #{instance_variable_get(i)}\n" }
    s
  end
  
  def dup
    Marshal::load(Marshal::dump(self))
  end
end
