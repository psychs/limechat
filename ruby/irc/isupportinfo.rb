# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

class ISupportInfo
  attr_reader :mode
  
  def initialize
    @mode = ModeInfo.new
    reset
  end
  
  def reset
    @features = {
      :channeltypes => '#&!+',
      :nicklen => 9,
    }
    @mode.reset
  end
  
  def [](key)
    @features[key]
  end
  
  def nicklen
    @features[:nicklen]
  end
  
  def modes_count
    @mode.count
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
      when :chanmodes; @mode.parse_chanmodes(value)
      when :modes; @mode.parse_modes(value)
      when :prefix; @mode.parse_prefix(value)
      else
        value = value.to_i if value =~ /\A\d+\z/
        @features[key] = value
      end
    elsif !s.empty? && !s.include?("\0")
      @features[s.downcase.to_sym] = true
    end
  end
  
  
  class ModeInfo
    attr_reader :count
    
    def initialize
      reset
    end
    
    def reset
      parse_modes('3')
      parse_prefix('(ov)@+')
      parse_chanmodes('beIR,k,l,imnpstaqr')
    end
  
    def parse_modestr(modestr)
      str = modestr.dup
      ary = []
      plus = false
      until str.empty?
        token = str.token!
        if /^([-+])(.+)$/ =~ token
          plus = ($1 == '+')
          token = $2
          token.each_char do |char|
            c = char.to_sym
            case c
            when :-; plus = false
            when :+; plus = true
            else
              if op_mode?(c)
                ary << {:mode => c, :plus => plus, :param => str.token!, :op_mode => true}
              elsif has_param?(c, plus)
                ary << {:mode => c, :plus => plus, :param => str.token!}
              else
                ary << {:mode => c, :plus => plus, :simple_mode => (@modemap[c] == 3)}
              end
            end
          end
        end
      end
      ary
    end
    
    def parse_modes(s)
      @count = s.to_i
      @count = 3 if @count <= 0
    end
    
    def parse_prefix(s)
      if s =~ /\A\(([^()]+)\)([^()]+)\z/
        @ops, marks = $1, $2
        @opmap = @ops.scan(/./).zip(marks.scan(/./)).inject({}) {|v,i| v[i[0].to_sym] = i[1]; v}
      end
    end
    
    def parse_chanmodes(s)
      @modemap = {}
      @modes = s.split(',', 4)
      @modes.each_with_index do |i,n|
        i.scan(/./).each {|s| @modemap[s.to_sym] = n}
      end
    end
    
    private
    
    def op_mode?(c)
      !!@opmap[c]
    end
    
    def has_param?(c, plus)
      return true if @opmap[c]
      case @modemap[c]
      when 0; true
      when 1; true
      when 2; plus
      else; false
      end
    end
  end
  
end
