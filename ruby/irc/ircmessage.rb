# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

module IRC
  MSG_LEN = 510
  BODY_LEN = 500
  ADDRESS_LEN = 50
end

module Penalty
  NORMAL = 2
  PART = 4
  KICK_BASE = 1
  KICK_OPT = 3
  MODE_BASE = 1
  MODE_OPT = 3
  TOPIC = 3
  INIT = 0
  MAX = 10
  TEXT_SIZE_FACTOR = 120
end


class IRCSendMessage
  attr_reader :command, :params, :built
  attr_accessor :penalty, :complete_colon
  
  def initialize(command, *args)
    @built = false
    @command = command
    @params = args.select {|i| i}
    @penalty = Penalty::NORMAL
    @raw = nil
    @complete_colon = true
  end
  
  def build
    return if @built
    
    force_complete_colon = false
    case @command
    when :privmsg,:notice
      force_complete_colon = true
    when :nick,:mode,:join,:names,:who,:list,:invite,:whois,:whowas,:ison
      @complete_colon = false
    end
    
    s = @command.to_s.upcase
    if @params.size > 0
      if @params.size > 1
        s << ' '
        s << @params[0...-1].join(' ')
      end
      s << ' '
      last = @params.last
      s << ':' if force_complete_colon || @complete_colon && (last.size == 0 || last =~ /^:|\s/)
      s << last
    end
    s << "\x0d\x0a"
    @raw = s
    
    if @penalty == Penalty::NORMAL
      case @command.to_sym
      when :privmsg,:notice; @penalty += @raw.size / Penalty::TEXT_SIZE_FACTOR
      when :mode; @penalty = ChannelMode.calc_penalty(@params[1])
      when :part; @penalty = Penalty::PART
      when :topic; @penalty = Penalty::TOPIC
      when :kick; @penalty = Penalty::KICK_BASE + Penalty::KICK_OPT
      end
    end
    @penalty = Penalty::MAX if @penalty > Penalty::MAX
    
    @built = true
  end
  
  def apply!
    if block_given?
      @params.map! {|i| yield i}
      @raw = yield @raw if @raw
    end
    self
  end
  
  def to_s
    build
    @raw
  end
end


class IRCReceiveMessage
  attr_reader :sender, :sender_nick, :sender_username, :sender_address, :command, :numeric_reply
  
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
    return if s.empty?
    if /^:([^ ]+)/ =~ s
      @sender = $1
      if /([^!@]+)!([^!@]+)@([^!@]+)/ =~ @sender
        @sender_nick = $1
        @sender_username = $2
        @sender_address = $3
      else
        @sender_nick = @sender.dup
      end
      s = str.token!
      return if s.empty?
    end
    
    if /^\d+$/ =~ s
      @command = s.to_sym
      @numeric_reply = s.to_i
    else
      @command = s.downcase.to_sym
    end
    
    loop do
      break if str.empty?
      if /^:/ =~ str
        @params << $~.post_match
        break
      end
      s = str.token!
      break if s.empty?
      s.rstrip!
      @params << s
    end
  end
  
  def [](n)
    @params[n] || ''
  end
  
  def sequence(n=0)
    ary = @params[n..-1]
    if ary
      ary.join(' ')
    else
      ''
    end
  end
  
  def apply!
    if block_given?
      @raw = yield @raw
      @sender = yield @sender
      @sender_nick = yield @sender_nick
      @sender_username = yield @sender_username
      @sender_address = yield @sender_address
      @params.map! {|i| yield i }
    end
    self
  end
  
  def to_s
    @raw
  end
end


class ISupportInfo
  def initialize
    reset
  end
  
  def reset
    @features = {
      :chanmodes => 'beIR,k,l,imnpstaqr'.split(','),
      :channeltypes => '#&!+',
      :modes => 3,
      :nicklen => 9,
    }
  end
  
  def [](key)
    @features[key]
  end
  
  def nicklen
    @features[:nicklen]
  end
  
  def modes_count
    @features[:modes]
  end
  
  def update(s)
    s = s.sub(/ are supported by this server\Z/, '')
    s.split(' ').each {|i| parse_param(i)}
  end
  
  private
  
  def parse_param(s)
    if s =~ /\A([-_a-zA-Z0-9]+)=(.*)\z/
      key, value = $1.downcase.to_sym, $2
      case key
      when :chanmodes
        @features[key] = value.split(',', 4)
      else
        value = value.to_i if value =~ /\A[0-9]+\z/
        @features[key] = value
      end
    elsif !s.empty? && !s.include?("\0")
      @features[s.downcase.to_sym] = true
    end
  end
end
