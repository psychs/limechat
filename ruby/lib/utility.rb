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
    index('.') != nil
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
  end
  
  class NSSize
    def dup; NSSize.new(width, height); end
  end
  
  class NSRect
    def dup; NSRect.new(origin, size); end
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
      case oc_type
      when NSLeftMouseDown
        puts 'NSLeftMouseDown'
      when NSLeftMouseUp
        puts 'NSLeftMouseUp'
      when NSRightMouseDown
        puts 'NSRightMouseDown'
      when NSRightMouseUp
        puts 'NSRightMouseUp'
      when NSOtherMouseDown
        puts 'NSOtherMouseDown'
      when NSOtherMouseUp
        puts 'NSOtherMouseUp'
      when NSMouseMoved
        puts 'NSMouseMoved'
      when NSLeftMouseDragged
        puts 'NSLeftMouseDragged'
      when NSRightMouseDragged
        puts 'NSRightMouseDragged'
      when NSOtherMouseDragged
        puts 'NSOtherMouseDragged'
      when NSMouseEntered
        puts 'NSMouseEntered'
      when NSMouseExited
        puts 'NSMouseExited'
      when NSKeyDown
        puts 'NSKeyDown'
      when NSKeyUp
        puts 'NSKeyUp'
      when NSFlagsChanged
        puts 'NSFlagsChanged'
      when NSAppKitDefined
        puts 'NSAppKitDefined'
      when NSSystemDefined
        puts 'NSSystemDefined'
      when NSApplicationDefined
        puts 'NSApplicationDefined'
      when NSPeriodic
        puts 'NSPeriodic'
      when NSCursorUpdate
        puts 'NSCursorUpdate'
      when NSScrollWheel
        puts 'NSScrollWheel'
      else
        puts 'else'
      end  
    end
  end
end
