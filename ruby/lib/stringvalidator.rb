# Public domain.
# http://webos-goodies.jp/archives/51072404.html

module StringValidator
  
  def validate_utf8(str, malformed_chr)
    code  = 0
    rest  = 0
    range = nil
    ucs   = []
    str.each_byte do |c|
      if rest <= 0
        case c
        when 0x01..0x7f then rest = 0 ; ucs << c
        when 0xc0..0xdf then rest = 1 ; code = c & 0x1f ; range = 0x00080..0x0007ff
        when 0xe0..0xef then rest = 2 ; code = c & 0x0f ; range = 0x00800..0x00ffff
        when 0xf0..0xf7 then rest = 3 ; code = c & 0x07 ; range = 0x10000..0x10ffff
        else                 ucs << malformed_chr
        end
      elsif 0x80..0xbf === c
        code = (code << 6) | (c & 0x3f)
        if (rest -= 1) <= 0
          if !(range === code) || (0xd800..0xdfff) === code
            code = malformed_chr
          end
          ucs << code
        end
      else
        ucs << malformed_chr
        rest = 0
      end
    end
    ucs.pack('U*')
  end
  
  extend self
end
