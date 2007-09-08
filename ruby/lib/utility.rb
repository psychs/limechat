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
    include?('.')
  end
  
  def expand_path
    OSX::NSString.stringWithString(self).stringByExpandingTildeInPath.to_s
  end
  
  def to_nsstr
    OSX::NSMutableString.stringWithString(self)
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
  
  def to_indexset
    set = OSX::NSMutableIndexSet.alloc.init
    each {|i| set.addIndex(i) }
    set
  end
  
  def to_nsary
    OSX::NSMutableArray.arrayWithArray(self)
  end
end

class Hash
  def to_nsdic
    OSX::NSMutableDictionary.dictionaryWithDictionary(self)
  end
end

class Numeric
  def grouped_by_comma
    s = to_s
    nil while s.gsub!(/(.*\d)(\d\d\d)/, '\1,\2')
    s
  end
end

module OSX
  class NSObject
    def to_ruby
      case self 
      when OSX::NSDate
        to_time
      when OSX::NSCFBoolean
        boolValue
      when OSX::NSNumber
        is_float? ? to_f : to_i
      when OSX::NSString
        to_s
      when OSX::NSAttributedString
        string.to_s
      when OSX::NSArray,OSX::NSIndexSet
        to_a.map {|x| x.is_a?(OSX::NSObject) ? x.to_ruby : x }
      when OSX::NSDictionary
        h = {}
        each do |x, y| 
          x = x.to_ruby if x.is_a?(OSX::NSObject)
          y = y.to_ruby if y.is_a?(OSX::NSObject)
          x = x.to_sym if x.is_a?(String)
          h[x] = y
        end
        h
      else
        self
      end
    end
  end
  
  class NSNumber
    def is_float?
      OSX::CFNumberIsFloatType(self)
    end
    
    def inspect
      "NS:#{to_ruby}"
    end
  end
  
  class NSString
    def inspect
      %Q[NS:#{to_ruby.inspect}]
    end
  end
  
  class NSArray
    def inspect
      s = 'NS['
      s += to_a.map{|i| i.inspect }.join(', ')
      s += ']'
      s
    end
  end
  
  class NSDictionary
    def to_hash
      h = {}
      each {|k,v| h[k] = v }
      h
    end
    
    def inspect
      s = 'NS{'
      ary = []
      each {|k,v| ary << "#{k.inspect} => #{v.inspect}" }
      s += ary.join(', ')
      s += '}'
      s
    end
  end
  
  class NSIndexSet
    def inspect
      s = "#<NSIndexSet:"
      s += to_a.map{|i| i.inspect }.join(', ')
      s += '>'
      s
    end
  end
  
  class NSPoint
    def in(r); OSX::NSPointInRect(self, r); end
    alias_method :inRect, :in
    def +(v)
      if v.kind_of?(OSX::NSSize)
        NSPoint.new(x + v.width, y + v.height)
      else
        raise ArgumentException, "parameter should be NSSize"
      end
    end
    def -(v)
      if v.kind_of?(OSX::NSSize)
        NSPoint.new(x - v.width, y - v.height)
      else
        raise ArgumentException, "parameter should be NSSize"
      end
    end

    def inspect
      "#<NSPoint (#{x}, #{y})>"
    end
  end
  
  class NSSize
    def /(v); NSSize.new(width / v, height / v); end
    def *(v); NSSize.new(width * v, height * v); end
    def +(v); NSSize.new(width + v, height + v); end
    def -(v); NSSize.new(width - v, height - v); end
    
    def inspect
      "#<NSSize (#{width}, #{height})>"
    end
  end
  
  class NSRect
    def contain?(r)
      if r.kind_of?(NSRect)
        OSX::NSContainsRect(self, r)
      elsif r.kind_of?(NSPoint)
        OSX::NSPointInRect(r, self)
      else
        raise ArgumentException, "parameter should be NSRect or NSPoint"
      end
    end
    def intersect?(r); OSX::NSIntersectsRect(self, r); end
    def offset(dx, dy); OSX::NSOffsetRect(self, dx, dy); end
    def center; origin + (size / 2.0); end
    def adjustInRect(r)
      n = dup
      if r.x + r.width < n.x + n.width
        n.origin.x = r.x + r.width - n.width
      end
      if r.y + r.height < n.y + n.height
        n.origin.y = r.y + r.height - n.height
      end
      if n.x < r.x
        n.origin.x = r.x
      end
      if n.y < r.y
        n.origin.y = r.y
      end
      n
    end
    def self.from_dic(d); NSRect.new(d[:x], d[:y], d[:w], d[:h]); end
    def to_dic
      {
        :x => x,
        :y => y,
        :w => width,
        :h => height
      }
    end

    def inspect
      "#<NSRect (#{x}, #{y}, #{width}, #{height}>"
    end
  end
  
  class NSRange
    def inspect
      "#<NSRange (#{location}, #{length})>"
    end
  end
  
  class NSSelectionArray
    def to_a
      ary = []
      0.upto(count-1) {|i| ary << objectAtIndex(i) }
      ary
    end
  end
  
  class NSWindow
    def centerOfScreen
      scr = OSX::NSScreen.screens[0]
      if scr
        p = scr.visibleFrame.center
        p -= frame.size / 2
        setFrameOrigin(p)
      else
        center
      end
    end
    
    def centerOfWindow(window)
      p = window.frame.center
      p -= frame.size / 2
      scr = window.screen
      if scr
        sf = scr.visibleFrame
        f = frame
        f.origin = p
        unless sf.contain?(f)
          f = f.adjustInRect(sf)
          p = f.origin
        end
      end
      setFrameOrigin(p)
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
