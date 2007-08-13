# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

class UserMode
  attr_accessor :a, :i, :r, :s, :w, :o, :O
  
  def initialize
    clear
  end
  
  def clear
    @a = @i = @r = @s = @w = @o = @O = false
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
          when 'a'; @a = plus
          when 'i'; @i = plus
          when 'r'; @r = plus
          when 's'; @s = plus
          when 'w'; @w = plus
          when 'o'; @o = plus
          when 'O'; @O = plus
          end
        end
      end
    end
  end
  
  SIMPLE_MODES = [:a, :i, :r, :s, :w, :o, :O]
  
  def to_s
    str = ''
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
    str
  end
  
  def get_change_str(mode)
    str = ''
    SIMPLE_MODES.each do |name|
      to = mode.__send__(name)
      if instance_variable_get('@' + name.to_s) != to
        str += to ? '+' : '-'
        str += name.to_s
      end
    end
    str
  end
  
  def self.calc_penalty(modestr)
    penalty = Penalty::MODEBASE
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
          when 'a','i','r','s','w','o','O'
            penalty += Penalty::MODEOPT
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
end
