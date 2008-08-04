# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

class KeyEventHandler
  def initialize
    @handlermap = {}
  end
  
  def process_key_event(e)
    return false if e.oc_type != NSKeyDown
    im = NSInputManager.currentInputManager
    return false if im && !im.markedRange.empty?
    m = e.modifierFlags
    key = 0
    key |= 1 if m & NSControlKeyMask > 0
    key |= 2 if m & NSAlternateKeyMask > 0
    key |= 4 if m & NSShiftKeyMask > 0
    key |= 8 if m & NSCommandKeyMask > 0

    map = @handlermap[key]
    return false unless map
    k = e.keyCode
    handler = map[k]
    return false unless handler
    handler.call(CODEMAP[k])
  end
  
  def register_key_handler(keys, *mods, &handler)
    m = 0
    mods.each do |i|
      case i
      when :ctrl;     m |= 1
      when :alt,:opt; m |= 2
      when :shift;    m |= 4
      when :cmd;      m |= 8
      end
    end
    keys = self.class.keynames_to_keycodes(keys)
    map = @handlermap[m]
    unless map
      map = {}
      @handlermap[m] = map
    end
    keys.each {|i| map[i] = handler }
  end
  
  def self.mods_to_modifier(mods)
    m = 0
    mods.each do |i|
      case i
      when :ctrl;     m |= NSControlKeyMask
      when :alt,:opt; m |= NSAlternateKeyMask
      when :shift;    m |= NSShiftKeyMask
      when :cmd;      m |= NSCommandKeyMask
      end
    end
    m
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
        codes = NAMEMAP[i]
        if codes
          if Array === codes
            result.concat(codes)
          else
            result << codes
          end
        end
      end
    end
    result
  end
  
  private

  CODEMAP = {
      0 => :a,
      1 => :s,
      2 => :d,
      3 => :f,
      4 => :h,
      5 => :g,
      6 => :z,
      7 => :x,
      8 => :c,
      9 => :v,
     11 => :b,
     12 => :q,
     13 => :w,
     14 => :e,
     15 => :r,
     16 => :y,
     17 => :t,
     18 => :"1",
     19 => :"2",
     20 => :"3",
     21 => :"4",
     22 => :"6",
     23 => :"5",
     24 => :"=",
     25 => :"9",
     26 => :"7",
     27 => :-,
     28 => :"8",
     29 => :"0",
     30 => :"]",
     31 => :o,
     32 => :u,
     33 => :"[",
     34 => :i,
     35 => :p,
     36 => :enter,
     37 => :l,
     38 => :j,
     39 => :"'",
     40 => :k,
     41 => :";",
     42 => :"\\",
     43 => :",",
     44 => :/,
     45 => :n,
     46 => :m,
     47 => :".",
     48 => :tab,
     49 => :space,
     50 => :`,
     51 => :backspace,
     53 => :esc,
     65 => :".",
     67 => :*,
     69 => :+,
     71 => :clear,
     75 => :/,
     76 => :enter,
     78 => :-,
     82 => :"0",
     83 => :"1",
     84 => :"2",
     85 => :"3",
     86 => :"4",
     87 => :"5",
     88 => :"6",
     89 => :"7",
     91 => :"8",
     92 => :"9",
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
    :"'" => 39,
    :* => 67,
    :+ => 69,
    :"," => 43,
    :- => [27, 78],
    :"." => [47, 65],
    :/ => [44, 75],
    :";" => 41,
    :"=" => 24,
    :"[" => 33,
    :"\\" => 42,
    :"]" => 30,
    :` => 50,
    :"0" => [29, 82],
    :"1" => [18, 83],
    :"2" => [19, 84],
    :"3" => [20, 85],
    :"4" => [21, 86],
    :"5" => [23, 87],
    :"6" => [22, 88],
    :"7" => [26, 89],
    :"8" => [28, 91],
    :"9" => [25, 92],
    :a => 0,
    :b => 11,
    :c => 8,
    :d => 2,
    :e => 14,
    :f => 3,
    :g => 5,
    :h => 4,
    :i => 34,
    :j => 38,
    :k => 40,
    :l => 37,
    :m => 46,
    :n => 45,
    :o => 31,
    :p => 35,
    :q => 12,
    :r => 15,
    :s => 1,
    :t => 17,
    :u => 32,
    :v => 9,
    :w => 13,
    :x => 7,
    :y => 16,
    :z => 6,
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
