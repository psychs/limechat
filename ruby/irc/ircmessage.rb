# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

module IRC
  NICKLEN = 9
  BODY_LEN = 480
  MSG_LEN = 510
end

module Penalty
  NORMAL = 2
  PART = 4
  KICKBASE = 1
  KICKOPT = 3
  MODEBASE = 1
  MODEOPT = 3
  TOPIC = 3
  INIT = 0
  MAX = 10
end

class IRCSendMessage
  attr_accessor :command, :target, :trail, :penalty, :raw, :built
  
  def initialize
    @built = false
    @command = ''
    @target = ''
    @trail = ''
    @penalty = Penalty::NORMAL
    @raw = ''
  end
  
  def build
    return if @built
    
    s = @command.to_s.upcase
    unless @target.empty?
      s += ' '
      s += @target
    end
    unless @trail.empty?
      s += ' '
      s += @trail
    end
    s = s[0...IRC::MSG_LEN] if s.size > IRC::MSG_LEN
    s += "\r\n"
    @raw = s
    
    if @penalty == Penalty::NORMAL
      case @command.to_sym
      when :privmsg,:notice; @penalty += s.size / 100
      when :mode; @penalty = ChannelMode.calc_penalty(@trail)
      when :part; @penalty = Penalty::PART
      when :topic; @penalty = Penalty::TOPIC
      when :kick; @penalty = Penalty::KICKBASE + Penalty::KICKOPT
      end
    end
    @penalty = Penalty::MAX if @penalty > Penalty::MAX
    
    @built = true
  end
  
  def map!
    if block_given?
      #@command = yield @command
      @target = yield @target
      @trail = yield @trail
      @raw = yield @raw
    end
  end
  
  def to_s
    build
    @raw
  end
end

class IRCReceiveMessage
  attr_accessor :raw, :sender, :sender_nick, :sender_username, :sender_address, :command, :numeric_reply
  
  def initialize(str)
    @raw = str.dup
    @sender = ''
    @sender_nick = ''
    @sender_username = ''
    @sender_address = ''
    @command = ''
    @numeric_reply = 0
    @params = []
    
    str = str.dup
    s = str.token!
    return self if s.empty?
    if /^:([^ ]+)/ =~ s
      @sender = $1
      if /([^ !@]+)!([^ !@]+)@([^ !@]+)/ =~ @sender
        @sender_nick = $1
        @sender_username = $2
        @sender_address = $3
      else
        @sender_nick = @sender.dup
      end
      s = str.token!
      return self if s.empty?
    end
    
    if /^\d+$/ =~ s
      @command = s
      @numeric_reply = s.to_i
    else
      @command = s.downcase.to_sym
    end
    
    15.times do
      break if str.empty?
      if /^:/ =~ str
        @params << str[1..-1]
        str = ''
        break
      end
      s = str.token!
      break if s.empty?
      s.rstrip!
      @params << s
    end
    @params << str unless str.empty?
  end
  
  def count_params
    @params.size
  end
  
  def params
    ary = []
    15.times {|i| ary << param(i) }
    ary
  end
  
  def param(i)
    if i < @params.size
      @params[i]
    else
      ''
    end
  end
  
  def [](n)
    param(n)
  end
  
  def sequence(n=0)
    @params[n..-1].join(' ')
  end
  
  def map!
    if block_given?
      @raw = yield @raw
      @sender = yield @sender
      @sender_nick = yield @sender_nick
      @sender_username = yield @sender_username
      @sender_address = yield @sender_address
      #@command = yield @command
      @params.map! {|i| yield i }
    end
  end
  
  def to_s
    @raw
  end
end
