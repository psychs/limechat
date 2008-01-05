# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

module KanaSupport
  
  def iso2022_to_native(str)
    enc = :other
    s = ''
    i = 0
    len = str.size
    while i < len
      c = str[i]
      if c == 0x1b
        seq = false
        d = str[i+1]
        e = str[i+2]
        case d
        when ?$
          case e
          when ?B,?b,?@
            enc = :other
          end
        when ?(
          case e
          when ?B,?b
            enc = :other
          when ?I,?i
            enc = :jisroman
            seq = true
            s << "\x1b(J"
          end
        end
        if seq
          i += 3
          next
        end
      end
      
      if enc == :jisroman
        c |= 0x80 if 0x21 <= c && c <= 0x5f
      end
      
      s << c.chr
      i += 1
    end      
    s
  end
  
  def to_iso2022(str)
    enc = :other
    s = ''
    i = 0
    len = str.size
    while i < len
      c = str[i]
      if c == 0x1b
        seq = false
        d = str[i+1]
        e = str[i+2]
        case d
        when ?$
          case e
          when ?B,?b,?@
            enc = :other
          end
        when ?(
          case e
          when ?B,?b
            enc = :other
          when ?J,?j
            enc = :jisroman
            seq = true
            s << "\x1b(I"
          when ?I,?i
            enc = :jiskana
          end
        end
        if seq
          i += 3
          next
        end
      end
      
      case enc
      when :jisroman
        if c == 0xe   # SO
          enc = :jiskana
          i += 1
          next
        end
      when :jiskana
        if c == 0xf   # SI
          enc = :jisroman
          i += 1
          next
        end
      end
      
      if enc == :jisroman
        c &= 0x7f if 0xa1 <= c && c <= 0xdf
      end
      
      s << c.chr
      i += 1
    end
    s
  end
  
  extend self
end
