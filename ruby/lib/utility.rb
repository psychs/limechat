# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

class String
  def first_char
    scan(/./)[0]
  end
  
  def each_char
    scan(/./) {|c| yield c }
  end
  
  def token!
    if / *([^ ]+) */ =~ self
      self[0...$&.length] = ''
      $1
    else
      replace('')
    end
  end
  
  def channelname?
    if /\A[#&+!]/ =~ self
      true
    else
      false
    end
  end
  
  def modechannelname?
    if /\A[#&!]/ =~ self
      true
    else
      false
    end
  end
  
  def server?
    !index('.')
  end
  
  def expand_path
    OSX::NSString.stringWithString(self).stringByExpandingTildeInPath.to_s
  end
end

class Array
  alias :orginal_index :index
  def index(*args)
    if block_given?
      each_with_index {|e,i| return i if yield e }
      nil
    else
      orginal_index(*args)
    end
  end
end

class True
  def to_i; 1; end
end

class False
  def to_i; 0; end
end

class Fixnum
  def grouped_by_comma
    s = to_s
    nil while s.gsub!(/(.*\d)(\d\d\d)/, '\1,\2')
    s
  end
end

class Bignum
  def grouped_by_comma
    s = to_s
    nil while s.gsub!(/(.*\d)(\d\d\d)/, '\1,\2')
    s
  end
end

module OSX
  class NSPoint
    def dup; NSPoint.new(x, y); end
    def +(v)
      if v.kind_of?(NSSize)
        NSPoint.new(x + v.width, y + v.height)
      else
        raise ArgumentException, "parameter should be NSSize"
      end
    end
    def -(v)
      if v.kind_of?(NSSize)
        NSPoint.new(x - v.width, y - v.height)
      else
        raise ArgumentException, "parameter should be NSSize"
      end
    end
  end
  
  class NSSize
    def dup; NSSize.new(width, height); end
    def /(v); NSSize.new(width / v, height / v); end
    def *(v); NSSize.new(width * v, height * v); end
  end
  
  class NSRect
    def dup; NSRect.new(origin, size); end
    def center; origin + (size / 2.0); end
    def self.from_dic(d); NSRect.new(d[:x], d[:y], d[:w], d[:h]); end
    def to_dic
      {
        :x => origin.x,
        :y => origin.y,
        :w => size.width,
        :h => size.height
      }
    end
  end
  
  class NSEvent
    def printType
      s = case oc_type
      when NSLeftMouseDown; 'NSLeftMouseDown'
      when NSLeftMouseUp; 'NSLeftMouseUp'
      when NSRightMouseDown; 'NSRightMouseDown'
      when NSRightMouseUp; 'NSRightMouseUp'
      when NSOtherMouseDown; 'NSOtherMouseDown'
      when NSOtherMouseUp; 'NSOtherMouseUp'
      when NSMouseMoved; 'NSMouseMoved'
      when NSLeftMouseDragged; 'NSLeftMouseDragged'
      when NSRightMouseDragged; 'NSRightMouseDragged'
      when NSOtherMouseDragged; 'NSOtherMouseDragged'
      when NSMouseEntered; 'NSMouseEntered'
      when NSMouseExited; 'NSMouseExited'
      when NSKeyDown; 'NSKeyDown'
      when NSKeyUp; 'NSKeyUp'
      when NSFlagsChanged; 'NSFlagsChanged'
      when NSAppKitDefined; 'NSAppKitDefined'
      when NSSystemDefined; 'NSSystemDefined'
      when NSApplicationDefined; 'NSApplicationDefined'
      when NSPeriodic; 'NSPeriodic'
      when NSCursorUpdate; 'NSCursorUpdate'
      when NSScrollWheel; 'NSScrollWheel'
      else 'else'
      end
      puts s
    end
  end
end
