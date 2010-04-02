# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

class KeyEventHandler
  def initialize
    @code_handler_map = {}
    @str_handler_map = {}
  end
  
  def process_key_event(e)
    return false if e.oc_type != NSKeyDown
    im = NSInputManager.currentInputManager
    return false if im && !im.markedRange.empty?
    
    m = e.modifierFlags
    key = 0
    key |= 1 if m & NSShiftKeyMask > 0
    key |= 2 if m & NSControlKeyMask > 0
    key |= 4 if m & NSAlternateKeyMask > 0
    key |= 8 if m & NSCommandKeyMask > 0

    if map = @code_handler_map[key]
      k = e.keyCode
      if handler = map[k]
        handler.call(CODEMAP[k])
        return true
      end
    end
    
    s = e.charactersIgnoringModifiers
    if s && s.length > 0
      if map = @str_handler_map[key]
        k = s[0]
        if handler = map[k]
          handler.call(s)
          return true
        end
      end
    end
    
    false
  end
  
  def register_keyHandler(keys, *mods, &handler)
    m = 0
    mods.each do |i|
      case i
      when :shift;    m |= 1
      when :ctrl;     m |= 2
      when :alt,:opt; m |= 4
      when :cmd;      m |= 8
      end
    end
    
    unless code_map = @code_handler_map[m]
      @code_handler_map[m] = code_map = {}
    end
    unless str_map = @str_handler_map[m]
      @str_handler_map[m] = str_map = {}
    end
    
    keys = self.class.keynames_to_keycodes(keys)
    keys.each do |i|
      case i
      when Numeric
        code_map[i] = handler
      when Symbol
        str_map[i.to_s[0]] = handler
      end
    end
  end
  
  def self.keynames_to_keycodes(keys)
    result = []
    keys = [keys] unless Array === keys
    keys.each do |i|
      case i
      when Numeric
        result << i.to_i
      when Range
        result.concat(keynames_to_keycodes(i.to_a))
      when Symbol,String
        i = i.to_sym if String === i
        if codes = NAMEMAP[i]
          if Array === codes
            result.concat(codes)
          else
            result << codes
          end
        else
          result << i
        end
      end
    end
    result
  end
  
  private

  CODEMAP = {
     36 => :enter,
     48 => :tab,
     49 => :space,
     51 => :backspace,
     53 => :esc,
     71 => :clear,
     76 => :enter,
     96 => :f5,
     97 => :f6,
     98 => :f7,
     99 => :f3,
    100 => :f8,
    101 => :f9,
    103 => :f11,
    105 => :f13,
    106 => :f16,
    107 => :f14,
    109 => :f10,
    111 => :f12,
    113 => :f15,
    114 => :help,
    115 => :home,
    116 => :pageup,
    117 => :delete,
    118 => :f4,
    119 => :end,
    120 => :f2,
    121 => :pagedown,
    122 => :f1,
    123 => :left,
    124 => :right,
    125 => :down,
    126 => :up,
  }

  NAMEMAP = {
    :backspace => 51,
    :clear => 71,
    :delete => 117,
    :down => 125,
    :end => 119,
    :enter => [36, 76],
    :esc => 53,
    :help => 114,
    :home => 115,
    :left => 123,
    :pagedown => 121,
    :pageup => 116,
    :right => 124,
    :space => 49,
    :tab => 48,
    :up => 126,
    :f1 => 122,
    :f2 => 120,
    :f3 => 99,
    :f4 => 118,
    :f5 => 96,
    :f6 => 97,
    :f7 => 98,
    :f8 => 100,
    :f9 => 101,
    :f10 => 109,
    :f11 => 103,
    :f12 => 111,
    :f13 => 105,
    :f14 => 107,
    :f15 => 113,
    :f16 => 106,
  }
end
