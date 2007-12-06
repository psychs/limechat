# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

class ChannelMode
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
  
  def update(modestr)
    str = modestr.dup
    plus = false
    until str.empty?
      token = str.token!
      if /^([-+])(.+)$/ =~ token
        plus = ($1 == '+')
        token = $2
        token.each_char do |char|
          case char
          when '-'; plus = false
          when '+'; plus = true
          when 'O','o','v','b','e','I','R'; str.token!
          when 'a'; @a = plus
          when 'i'; @i = plus
          when 'm'; @m = plus
          when 'n'; @n = plus
          when 'p'; @p = plus
          when 'q'; @q = plus
          when 'r'; @r = plus
          when 's'; @s = plus
          when 't'; @t = plus
          when 'k'
            key = str.token!
            @k = plus ? key : ''
          when 'l'
            @l = plus ? str.token!.to_i : 0
          end
        end
      end
    end
  end
  
  SIMPLE_MODES = [:p, :s, :m, :n, :t, :i, :a, :q, :r]
  
  def to_s
    _to_s
  end
  
  def masked_str
    _to_s(true)
  end
  
  def get_change_str(mode)
    str = ''
    trail = ''
    SIMPLE_MODES.each do |name|
      to = mode.__send__(name)
      if instance_variable_get('@' + name.to_s) != to
        str += to ? '+' : '-'
        str += name.to_s
      end
    end
    if @l != mode.l
      if mode.l > 0
        str += '+l'
        trail += " #{mode.l}"
      else
        str += '-l'
      end
    end
    if @k != mode.k
      if @k.empty?
        str += '+k'
        trail += " #{mode.k}"
      else
        str += '-k'
        trail += " #{@k}"
        unless mode.k.empty?
          return [str + trail, "+k #{mode.k}"]
        end
      end
    end
    [str + trail]
  end
  
  def self.calc_penalty(modestr)
    penalty = Penalty::MODE_BASE
    str = modestr.dup
    plus = false
    until str.empty?
      token = str.token!
      if /^([-+])(.+)$/ =~ token
        plus = ($1 == '+')
        token = $2
        token.each_char do |char|
          case char
          when '-'; plus = false
          when '+'; plus = true
          when 'a','i','m','n','p','q','r','s','t','w'
            penalty += Penalty::MODE_OPT
          when 'O','o','v','b','e','I','R','k'
            str.token!
            penalty += Penalty::MODE_OPT
          when 'l'
            penalty += Penalty::MODE_OPT if plus
          end
        end
      end
    end
    penalty = Penalty::MAX if penalty > Penalty::MAX
    penalty
  end
  
  def dup
    Marshal::load(Marshal::dump(self))
  end
  
  private
  
  def _to_s(mask=false)
    str = ''
    trail = ''
    plus = false
    SIMPLE_MODES.each do |name|
      if instance_variable_get('@' + name.to_s)
        unless plus
          plus = true
          str += '+'
        end
        str += name.to_s
      end
    end
    if @l > 0
      str += "+l"
      trail += " #{@l}"
    end
    unless @k.empty?
      str += '+k'
      trail += " #{@k}" unless mask
    end
    str + trail
  end
end
