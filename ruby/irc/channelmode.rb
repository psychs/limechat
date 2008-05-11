# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

class ChannelMode
  attr_writer :info
  attr_accessor :a, :i, :m, :n, :p, :q, :r, :s, :t
  attr_reader :k, :l
  
  def initialize
    clear
  end
  
  def clear
    @a = @i = @m = @n = @p = @q = @r = @s = @t = false
    @k = ''
    @l = 0
  end
  
  def k=(v)
    @k = v ? v : ''
  end
  
  def l=(v)
    @l = v ? v : 0
  end
  
  SIMPLE_MODES = [:p, :s, :m, :n, :t, :i, :a, :q, :r]
  
  def update(modestr)
    i = @info.parse_modestr(modestr)
    i.each do |h|
      unless h[:op_mode]
        mode = h[:mode]
        plus = h[:plus]
        if h[:simple_mode] && SIMPLE_MODES.include?(mode)
          instance_variable_set("@#{mode}", plus)
        else
          case mode
          when :k
            param = h[:param] || ''
            @k = plus ? param : ''
          when :l
            if plus
              param = h[:param] || 0
              @l = param.to_i
            else
              @l = 0
            end
          end
        end
      end
    end
    i
  end
  
  def get_change_str(mode)
    str = ''
    trail = ''
    SIMPLE_MODES.each do |name|
      to = mode.__send__(name)
      if instance_variable_get("@#{name}") != to
        str << (to ? '+' : '-')
        str << name.to_s
      end
    end
    if @l != mode.l
      if mode.l > 0
        str << '+l'
        trail << " #{mode.l}"
      else
        str << '-l'
      end
    end
    if @k != mode.k
      if @k.empty?
        str << '+k'
        trail << " #{mode.k}"
      else
        str << '-k'
        trail << " #{@k}"
        unless mode.k.empty?
          return [str + trail, "+k #{mode.k}"]
        end
      end
    end
    [str + trail]
  end
  
  def self.calc_penalty(modestr)
    return Penalty::MODE_BASE unless modestr
    str = modestr.dup
    count = 0
    until str.empty?
      token = str.token!
      if /^([-+])(.+)$/ =~ token
        token = $2
        token.each_char do |char|
          c = char.to_sym
          case c
          when :-,:+
          else
            count += 1
          end
        end
      end
    end
    penalty = Penalty::MODE_BASE + Penalty::MODE_OPT * count
    penalty = Penalty::MAX if penalty > Penalty::MAX
    penalty
  end
  
  def dup
    obj = ChannelMode.new
    instance_variables.each do |i|
      name = i[1..-1] + '='
      value = instance_variable_get(i)
      value = value.dup if value.is_a?(String)
      obj.__send__(name, value)
    end
    obj
  end
  
  def to_s
    _to_s
  end
  
  def masked_str
    _to_s(true)
  end
  
  private
  
  def _to_s(mask=false)
    str = ''
    trail = ''
    plus = false
    SIMPLE_MODES.each do |name|
      if instance_variable_get("@#{name}")
        unless plus
          plus = true
          str << '+'
        end
        str << name.to_s
      end
    end
    if @l > 0
      str << "+l"
      trail << " #{@l}"
    end
    unless @k.empty?
      str << '+k'
      trail << " #{@k}" unless mask
    end
    str + trail
  end
end
