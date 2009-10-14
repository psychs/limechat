# Copyright (c) 2006-2008, The RubyCocoa Project.
# Copyright (c) 2001-2006, FUJIMOTO Hisakuni.
# All Rights Reserved.
#
# RubyCocoa is free software, covered under either the Ruby's license or the 
# LGPL. See the COPYRIGHT file for more information.

require 'osx/objc/oc_wrapper'

OSX._ignore_ns_override = true
  
module OSX
  
  # Utility for private use
  module RangeUtil
    def self.normalize(range, count)
      n = range.first
      n += count if n < 0
      last = range.last
      last += count if last < 0
      last += 1 unless range.exclude_end?
      len = last - n
      len = 0 if len < 0
      len = count - n if count < n + len
      [n, len, last]
    end
  end

  # Enumerable module for NSValue types
  module NSEnumerable
    include Enumerable
    
    def grep(pattern)
      result = []
      if block_given?
        each {|i| result << (yield i) if pattern === i }
      else
        each {|i| result << i if pattern === i }
      end
      result.to_ns
    end
    
    def map
      result = []
      each {|i| result << (yield i) }
      result.to_ns
    end
    alias_method :collect, :map
    
    def select
      result = []
      each {|i| result << i if yield i }
      result.to_ns
    end
    alias_method :find_all, :select
    
    def partition
      selected = []
      others = []
      each do |i|
        if yield i
          selected << i
        else
          others << i
        end
      end
      [selected, others].to_ns
    end
    
    def reject
      result = []
      each {|i| result << i unless yield i }
      result.to_ns
    end
    
    def sort(&block)
      to_a.sort(&block).to_ns
    end
    
    def sort_by
      map {|i| [(yield i), i]}.sort {|a,b| a[0] <=> b[0]}.map! {|i| i[1]}
    end
    
    def zip(*args)
      if block_given?
        each_with_index do |obj,n|
          cur = []
          [self, *args].each {|i| cur << i[n] }
          yield cur
        end
        nil
      else
        result = []
        each_with_index do |obj,n|
          cur = []
          [self, *args].each {|i| cur << i[n] }
          result << cur
        end
        result.to_ns
      end
    end
  end

  # NSString additions
  class NSString
    include OSX::OCObjWrapper

    def dup
      mutableCopy
    end
    
    def clone
      obj = dup
      obj.freeze if frozen?
      obj.taint if tainted?
      obj
    end
    
    # enable to treat as String
    def to_str
      self.to_s
    end

    # comparison between Ruby String and Cocoa NSString
    def ==(other)
      if other.is_a? OSX::NSString
        isEqualToString?(other)
      elsif other.respond_to? :to_str
        self.to_s == other.to_str
      else
        false
      end
    end

    def <=>(other)
      if other.respond_to? :to_str
        self.to_str <=> other.to_str
      else
        nil
      end
    end

    def inspect
      "#<#{self.class.to_s.gsub(/^OSX::/, '')} \"#{self.to_s}\">"
    end

    def hash
      oc_hash
    end

    def pretty_print(q)
      self.to_s.pretty_print(q)
    end

    # responds to Ruby String methods
    alias_method :_rbobj_respond_to?, :respond_to?
    def respond_to?(mname, private = false)
      String.public_method_defined?(mname) or _rbobj_respond_to?(mname, private)
    end

    alias_method :objc_method_missing, :method_missing
    def method_missing(mname, *args, &block)
      if mname == :match || mname == :=~
        i = mname == :match ? 0 : 1
        warn "#{caller[i]}: 'NSString##{mname}' doesn't work correctly. Because it returns byte indexes. Please use 'String##{mname}' instead."
      end
      
      ## TODO: should test "respondsToSelector:"
      if String.public_method_defined?(mname) && (mname != :length)
        # call as Ruby string
        rcv = to_s
        org_val = rcv.dup
        result = rcv.send(mname, *args, &block)
        if result.__id__ == rcv.__id__
          result = self
        end
        # bang methods modify receiver itself, need to set the new value.
        # if the receiver is immutable, NSInvalidArgumentException raises.
        if rcv != org_val
          setString(rcv)
        end
      else
        # call as objc string
        result = objc_method_missing(mname, *args)
      end
      result
    end
    
    def =~(*args)
      method_missing(:=~, *args)
    end
    
    # For NSString duck typing

    def [](*args)
      _read_impl(:[], args)
    end
    alias_method :slice, :[]
    
    def []=(*args)
      count = length
      case args.length
      when 2
        first, second = args
        case first
        when Numeric,OSX::NSNumber
          n = first.to_i
          n += count if n < 0
          if n < 0 || count <= n
            raise IndexError, "index #{first.to_i} out of string"
          end
          self[n..n] = second
        when String,OSX::NSString
          str = first
          str = str.to_ns if str.is_a?(String)
          n = index(str)
          unless n
            raise IndexError, "string not matched"
          end
          self[n...n+str.length] = second
        when Range
          n, len = OSX::RangeUtil.normalize(first, count)
          if n < 0 || count < n
            raise RangeError, "#{first} out of range"
          end
          value = second
          case value
          when Numeric,OSX::NSNumber
            value = OSX::NSString.stringWithFormat("%C", value.to_i)
          when String,OSX::NSString
          else
            raise TypeError, "can't convert #{val.class} into String"
          end
          if len > 0
            deleteCharactersInRange(OSX::NSRange.new(n, len))
          end
          insertString_atIndex(value, n)
          value
        #when Regexp
        else
          raise TypeError, "can't convert #{first.class} into Integer"
        end
      when 3
        first = args.first
        case first
        when Numeric,OSX::NSNumber
          n, len, value = args
          unless len.is_a?(Numeric) || len.is_a?(OSX::NSNumber)
            raise TypeError, "can't convert #{len.class} into Integer"
          end
          n = n.to_i
          len = len.to_i
          n += count if n < 0
          if n < 0 || count < n
            raise IndexError, "index #{first.to_i} out of string"
          end
          if len < 0
            raise IndexError, "negative length (#{len})"
          end
          self[n...n+len] = value
        #when Regexp
        else
          raise TypeError, "can't convert #{first.class} into Integer"
        end
      else
        raise ArgumentError, "wrong number of arguments (#{args.length} for 3)"
      end
    end
    
    def %(args)
      if args.is_a?(Array) || args.is_a?(OSX::NSArray)
        args = args.map {|i| i.is_a?(OSX::NSObject) ? i.to_ruby : i }
      end
      (to_s % args).to_ns
    end

    def *(times)
      unless times.is_a?(Numeric) || times.is_a?(OSX::NSNumber)
        raise TypeError, "can't convert #{times.class} into Integer"
      end
      (to_s * times.to_i).to_ns
    end

    def +(other)
      unless other.is_a?(String) || other.is_a?(OSX::NSString)
        raise TypeError, "can't convert #{other.class} into String"
      end
      s = mutableCopy
      s.appendString(other)
      s
    end
    
    def <<(other)
      case other
      when Numeric,OSX::NSNumber
        i = other.to_i
        if 0 <= i && i < 65536
          appendString(OSX::NSString.stringWithFormat("%C", i))
        else
          raise TypeError, "can't convert #{other.class} into String"
        end
      when String,OSX::NSString
        appendString(other)
      else
        raise TypeError, "can't convert #{other.class} into String"
      end
      self
    end
    alias_method :concat, :<<
    
    def capitalize
      if length > 0
        substringToIndex(1).upcase + substringFromIndex(1).downcase
      else
        ''.to_ns
      end
    end
    
    def capitalize!
      s = capitalize
      if self != s
        setString(s)
        self
      else
        nil
      end
    end
    
    def casecmp(other)
      caseInsensitiveCompare(other)
    end
    
    def center(len, padstr=' ')
      if !len.is_a?(Numeric) && !len.is_a?(OSX::NSNumber)
        raise TypeError, "can't convert #{len.class} into Integer"
      end
      if !padstr.is_a?(String) && !padstr.is_a?(OSX::NSString)
        raise TypeError, "can't convert #{padstr.class} into String"
      end
      len = len.to_i
      padstr = padstr.to_ns if padstr.is_a?(String)
      padlen = padstr.length
      if padlen == 0
        raise ArgumentError, "zero width padding"
      end
      curlen = length
      if len <= curlen
        mutableCopy
      else
        len -= curlen
        leftlen = len / 2
        rightlen = len - leftlen
        s = ''.to_ns
        if leftlen > 0
          s << padstr * (leftlen / padlen)
          leftlen %= padlen
          s << padstr.substringToIndex(leftlen) if leftlen > 0
        end
        s << self
        if rightlen > 0
          s << padstr * (rightlen / padlen)
          rightlen %= padlen
          s << padstr.substringToIndex(rightlen) if rightlen > 0
        end
        s
      end
    end
    
    def chomp(rs=$/)
      return mutableCopy unless rs
      if rs.empty?
        prev = self
        while prev != (s = prev.chomp)
          prev = s
        end
        s
      else
        if rs == "\n"
          if hasSuffix("\r\n")
            substringToIndex(length-2).mutableCopy
          elsif hasSuffix("\n") || hasSuffix("\r")
            substringToIndex(length-1).mutableCopy
          else
            mutableCopy
          end
        else
          if hasSuffix(rs)
            rs = rs.to_ns if rs.is_a?(String)
            substringToIndex(length-rs.length).mutableCopy
          else
            mutableCopy
          end
        end
      end
    end
    
    def chomp!(rs=$/)
      s = chomp(rs)
      if self != s
        setString(s)
        self
      else
        nil
      end
    end
    
    def chop
      len = length
      if len == 0
        ''.to_ns
      elsif hasSuffix("\r\n")
        substringToIndex(len-2).mutableCopy
      else
        substringToIndex(len-1).mutableCopy
      end
    end
    
    def chop!
      s = chop
      if self != s
        setString(s)
        self
      else
        nil
      end
    end
    
    def chr
      if empty?
        ''.to_ns
      else
        substringToIndex(1).mutableCopy
      end
    end
    
    def clear
      setString('')
      self
    end
    
    def count(*chars)
      to_s.count(*chars)
    end
    
    def crypt(salt)
      to_s.crypt(salt.to_s).to_ns
    end
    
    def delete(*strs)
      to_s.delete(*strs).to_ns
    end
    
    def delete!(*strs)
      s = to_s
      result = s.delete!(*strs)
      if result
        setString(s)
        self
      else
        nil
      end
    end
    
    def downcase
      lowercaseString.mutableCopy
    end
    
    def downcase!
      s = lowercaseString
      if self != s
        setString(s)
        self
      else
        nil
      end
    end
    
    def dump
      to_s.dump.to_ns
    end
    
    def each_byte(&block)
      to_s.each_byte(&block)
      self
    end
    
    def each_line(rs=$/)
      if rs == nil
        yield mutableCopy
      else
        if rs.empty?
          paragraph_mode = true
          sep = $/*2
          lf = $/
          sep = sep.to_ns if sep.is_a?(String)
          lf = lf.to_ns if lf.is_a?(String)
        else
          paragraph_mode = false
          sep = rs
          sep = sep.to_ns if sep.is_a?(String)
        end
        
        pos = 0
        count = length
        loop do
          break if count <= pos
          n = index(sep, pos)
          unless n
            yield self[pos..-1]
            break
          end
          len = sep.length
          if paragraph_mode
            loop do
              start = n + len
              break if self[start,lf.length] != lf
              len += lf.length
            end
          end
          yield self[pos...n+len]
          pos = n + len
        end
      end
      self
    end
    alias_method :each, :each_line
    
    def empty?
      length == 0
    end
    
    def end_with?(str)
      hasSuffix(str)
    end
    
    def gsub(*args, &block)
      to_s.gsub(*args, &block).to_ns
    end
    
    def gsub!(*args, &block)
      s = to_s
      result = s.gsub!(*args, &block)
      if result
        setString(s)
        self
      else
        nil
      end
    end
    
    def hex
      to_s.hex
    end
    
    def include?(str)
      index(str) != nil
    end
    
    def index(pattern, pos=0)
      case pattern
      when Numeric,OSX::NSNumber
        i = pattern.to_i
        if 0 <= i && i < 65536
          s = OSX::NSString.stringWithFormat("%C", i)
        else
          return nil
        end
      when String,OSX::NSString
        s = pattern
        s = s.to_ns if s.is_a?(String)
      #when Regexp
      else
        raise TypeError, "can't convert #{pattern.class} into String"
      end
      
      if s.empty?
        0
      else
        len = length
        n = pos.to_i
        n += len if n < 0
        if n < 0 || len <= n
          return nil
        end
        range = rangeOfString_options_range(s, 0, OSX::NSRange.new(n, len - n))
        if range.not_found?
          nil
        else
          range.location
        end
      end
    end
    
    def insert(n, other)
      unless n.is_a?(Numeric) || n.is_a?(OSX::NSNumber)
        raise TypeError, "can't convert #{n.class} into Integer"
      end
      unless other.is_a?(String) || other.is_a?(OSX::NSString)
        raise TypeError, "can't convert #{other.class} into String"
      end
      n = n.to_i
      if n == -1
        appendString(other)
      else
        len = length
        n += len + 1 if n < 0
        if n < 0 || len < n
          raise IndexError, "index #{n} out of string"
        else
          insertString_atIndex(other, n)
        end
      end
      self
    end
    
    def intern
      to_s.intern
    end
    alias_method :to_sym, :intern
    
    def lines
      result = []
      each_line {|i| result << i }
      result.to_ns
    end
    
    def ljust(len, padstr=' ')
      if !len.is_a?(Numeric) && !len.is_a?(OSX::NSNumber)
        raise TypeError, "can't convert #{len.class} into Integer"
      end
      if !padstr.is_a?(String) && !padstr.is_a?(OSX::NSString)
        raise TypeError, "can't convert #{padstr.class} into String"
      end
      len = len.to_i
      padstr = padstr.to_ns if padstr.is_a?(String)
      padlen = padstr.length
      if padlen == 0
        raise ArgumentError, "zero width padding"
      end
      s = mutableCopy
      curlen = length
      if len <= curlen
        s
      else
        len -= curlen
        s << padstr * (len / padlen)
        len %= padlen
        s << padstr.substringToIndex(len) if len > 0
        s
      end
    end
    
    def lstrip
      cs = OSX::NSCharacterSet.characterSetWithCharactersInString(" \t\r\n\f\v").invertedSet
      r = rangeOfCharacterFromSet(cs)
      if r.not_found?
        ''.to_ns
      else
        substringFromIndex(r.location).mutableCopy
      end
    end
    
    def lstrip!
      s = lstrip
      if self != s
        setString(s)
        self
      else
        nil
      end
    end
    
    def next
      to_s.next.to_ns
    end
    alias_method :succ, :next
    
    def next!
      setString(self.next)
      self
    end
    alias_method :succ!, :next!

    def oct
      to_s.oct
    end
    
    def ord
      if length > 0
        characterAtIndex(0)
      else
        0
      end
    end
    
    def partition(sep)
      r = rangeOfString(sep)
      if r.not_found?
        left = mutableCopy
        right = ''.to_ns
        sep = right.mutableCopy
      else
        left = substringToIndex(r.location).mutableCopy
        right = substringFromIndex(r.location + r.length).mutableCopy
        sep = substringWithRange(r).mutableCopy
      end
      [left, sep, right].to_ns
    end
    
    def replace(other)
      setString(other)
      self
    end
    
    def reverse
      s = ''.to_ns
      (length-1).downto(0) do |i|
        s.appendFormat("%C", characterAtIndex(i))
      end
      s
    end
    
    def reverse!
      setString(reverse)
      self
    end
    
    def rindex(pattern, pos=self.length)
      case pattern
      when Numeric,OSX::NSNumber
        i = pattern.to_i
        if 0 <= i && i < 65536
          s = OSX::NSString.stringWithFormat("%C", i)
        else
          return nil
        end
      when String,OSX::NSString
        s = pattern
        s = s.to_ns if s.is_a?(String)
      #when Regexp
      else
        raise TypeError, "can't convert #{pattern.class} into String"
      end
      
      if s.empty?
        length
      else
        len = length
        n = pos.to_i
        n += len if n < 0
        if n < 0
          return nil
        end
        n += s.length
        n = len if len < n
        range = rangeOfString_options_range(s, OSX::NSBackwardsSearch, OSX::NSRange.new(0, n))
        if range.not_found?
          nil
        else
          range.location
        end
      end
    end
    
    def rjust(len, padstr=' ')
      if !len.is_a?(Numeric) && !len.is_a?(OSX::NSNumber)
        raise TypeError, "can't convert #{len.class} into Integer"
      end
      if !padstr.is_a?(String) && !padstr.is_a?(OSX::NSString)
        raise TypeError, "can't convert #{padstr.class} into String"
      end
      len = len.to_i
      padstr = padstr.to_ns if padstr.is_a?(String)
      padlen = padstr.length
      if padlen == 0
        raise ArgumentError, "zero width padding"
      end
      curlen = length
      if len <= curlen
        mutableCopy
      else
        s = ''.to_ns
        len -= curlen
        s << padstr * (len / padlen)
        len %= padlen
        s << padstr.substringToIndex(len) if len > 0
        s << self
        s
      end
    end
    
    def rpartition(sep)
      r = rangeOfString_options(sep, OSX::NSBackwardsSearch)
      if r.not_found?
        left = mutableCopy
        right = ''.to_ns
        sep = right.mutableCopy
      else
        left = substringToIndex(r.location).mutableCopy
        right = substringFromIndex(r.location + r.length).mutableCopy
        sep = substringWithRange(r).mutableCopy
      end
      [left, sep, right].to_ns
    end
    
    def rstrip
      cs = OSX::NSCharacterSet.characterSetWithCharactersInString(" \t\r\n\f\v").invertedSet
      r = rangeOfCharacterFromSet_options(cs, OSX::NSBackwardsSearch)
      if r.not_found?
        ''.to_ns
      else
        substringToIndex(r.location + 1).mutableCopy
      end
    end
    
    def rstrip!
      s = rstrip
      if self != s
        setString(s)
        self
      else
        nil
      end
    end
    
    def scan(re, &block)
      if block
        to_s.scan(re) {|i| block.call(i.to_ns)}.to_ns
      else
        to_s.scan(re).to_ns
      end
    end
    
    def size
      length
    end
    
    def slice!(*args)
      _read_impl(:slice!, args)
    end
    
    def split(sep=$;, limit=0)
      sep = sep.to_ns if sep.is_a?(String)
      result = []
      if sep && sep.empty?
        if limit > 0
          0.upto(limit-2) do |i|
            result << self[i..i]
          end
          result << substringFromIndex(limit-1).mutableCopy if limit < length
        else
          0.upto(length-1) {|i| result << self[i..i]}
          if limit == 0
            while last = result[-1] && last.empty?
              result.delete_at(-1)
            end
          end
        end
      else
        space = ' '.to_ns
        if sep.nil? || sep.isEqualTo(space)
          str = lstrip
          sep = space
        else
          str = self
        end
        
        n = nil
        pos = 0
        count = str.length
        
        loop do
          break if limit > 0 && result.size >= limit -1
          break if count <= pos
          n = str.index(sep, pos)
          break unless n
          len = sep.length
          s = str[pos...n]
          result << s unless s.empty? && sep == space
          pos = n + len
        end
        
        result << str.substringFromIndex(pos).mutableCopy
        
        if limit == 0
          while (last = result[-1]) && last.empty?
            result.delete_at(-1)
          end
        end
      end
      result.to_ns
    end
    
    def squeeze(*chars)
      to_s.squeeze(*chars).to_ns
    end
    
    def squeeze!(*chars)
      s = to_s
      result = s.squeeze!(*chars)
      if result
        setString(s)
        self
      else
        nil
      end
    end
    
    def start_with?(str)
      hasPrefix(str)
    end
    
    def strip
      cs = OSX::NSCharacterSet.characterSetWithCharactersInString(" \t\r\n\f\v")
      stringByTrimmingCharactersInSet(cs).mutableCopy
    end
    
    def strip!
      s = strip
      if self != s
        setString(s)
        self
      else
        nil
      end
    end
    
    def sub(*args, &block)
      to_s.sub(*args, &block).to_ns
    end
    
    def sub!(*args, &block)
      s = to_s
      result = s.sub!(*args, &block)
      if result
        setString(s)
        self
      else
        nil
      end
    end
    
    def sum(bits=16)
      bits = bits.to_i if bits.is_a?(OSX::NSNumber)
      n = 0
      0.upto(length-1) {|i| n += characterAtIndex(i) }
      n = n & ((1 << bits) - 1) if bits > 0
      n
    end
    
    def swapcase
      to_s.swapcase.to_ns
    end
    
    def swapcase!
      s = swapcase
      if self != s
        setString(s)
        self
      else
        nil
      end
    end
    
    def to_f
      to_s.to_f
    end
    
    def to_i(base=10)
      to_s.to_i(base)
    end
    
    def tr(pattern, replace)
      to_s.tr(pattern, replace).to_ns
    end
    
    def tr!(pattern, replace)
      s = to_s
      result = s.tr!(pattern, replace)
      if result
        setString(s)
        self
      else
        nil
      end
    end
    
    def tr_s(pattern, replace)
      to_s.tr_s(pattern, replace).to_ns
    end
    
    def tr_s!(pattern, replace)
      s = to_s
      result = s.tr_s!(pattern, replace)
      if result
        setString(s)
        self
      else
        nil
      end
    end
    
    def upcase
      uppercaseString.mutableCopy
    end
    
    def upcase!
      s = uppercaseString
      if self != s
        setString(s)
        self
      else
        nil
      end
    end
    
    def upto(max)
      max = max.to_ns unless max.is_a?(NSString)
      (self..max).each {|i| yield i}
      self
    end
    
    private
    
    def _read_impl(method, args)
      slice = method == :slice!
      count = length
      case args.length
      when 1
        first = args.first
        case first
        when Numeric,OSX::NSNumber
	  _read_impl_num(slice, first.to_i, count)
        when String,OSX::NSString
	  _read_impl_str(slice, first.to_ns)
        #when Regexp
        when Range
	  _read_impl_range(slice, first, count)
        else
          raise TypeError, "can't convert #{first.class} into Integer"
        end
      when 2
        first, second = args
        case first
        when Numeric,OSX::NSNumber
          unless second.is_a?(Numeric) || second.is_a?(OSX::NSNumber)
            raise TypeError, "can't convert #{second.class} into Integer"
          end
	  _read_impl_num_len(method, first.to_i, second.to_i, count)
        #when Regexp
        else
          raise TypeError, "can't convert #{first.class} into Integer"
        end
      else
        raise ArgumentError, "wrong number of arguments (#{args.length} for 2)"
      end
    end

    def _read_impl_num(slice, num, count)
      num += count if num < 0
      if 0 <= num && num < count
	c = characterAtIndex(num)
	deleteCharactersInRange(OSX::NSRange.new(num, 1)) if slice
	c
      else
	nil
      end
    end

    def _read_impl_str(slice, str)
      n = index(str)
      if n
	s = str.mutableCopy
	deleteCharactersInRange(OSX::NSRange.new(n, str.length)) if slice
	s
      else
	nil
      end
    end

    def _read_impl_range(slice, range, count)
      n, len = OSX::RangeUtil.normalize(range, count)
      if 0 <= n && n < count
	range = OSX::NSRange.new(n, len)
	s = substringWithRange(range).mutableCopy
	deleteCharactersInRange(range) if slice
	s
      elsif n == count
	''.to_ns
      else
	nil
      end
    end

    def _read_impl_num_len(method, num, len, count)
      num += count if num < 0
      if num < 0 || count < num
	nil
      elsif len < 0
	nil
      else
	_read_impl(method, [num...num+len])
      end
    end
  end

  # NSArray additions
  class NSArray
    include OSX::OCObjWrapper

    def dup
      mutableCopy
    end
    
    def clone
      obj = dup
      obj.freeze if frozen?
      obj.taint if tainted?
      obj
    end

    # enable to treat as Array
    def to_ary
      to_a
    end

    # comparison between Ruby Array and Cocoa NSArray
    def ==(other)
      if other.is_a? OSX::NSArray
        isEqualToArray?(other)
      elsif other.respond_to? :to_ary
        to_a == other.to_ary
      else
        false
      end
    end

    def <=>(other)
      if other.respond_to? :to_ary
        to_a <=> other.to_ary
      else
        nil
      end
    end

    # For NSArray duck typing
    
    def each
      iter = objectEnumerator
      while obj = iter.nextObject
        yield obj
      end
      self
    end

    def reverse_each
      iter = reverseObjectEnumerator
      while obj = iter.nextObject
        yield obj
      end
      self
    end

    def [](*args)
      _read_impl(:[], args)
    end
    alias_method :slice, :[]

    def []=(*args)
      count = self.count
      case args.length
      when 2
        case args.first
        when Numeric
          n, value = args
          unless n.is_a?(Numeric) || n.is_a?(OSX::NSNumber)
            raise TypeError, "can't convert #{n.class} into Integer"
          end
          if value == nil
            raise ArgumentError, "attempt insert nil to NSArray"
          end
          n = n.to_i
          n += count if n < 0
          if 0 <= n && n < count
            replaceObjectAtIndex_withObject(n, value)
          elsif n == count
            addObject(value)
          else
            raise IndexError, "index #{args[0]} out of array"
          end
          value
        when Range
          range, value = args
          n, len = OSX::RangeUtil.normalize(range, count)
          if n < 0 || count < n
            raise RangeError, "#{range} out of range"
          end
          
          if 0 <= n && n < count
            if len > 0
              removeObjectsInRange(OSX::NSRange.new(n, len))
            end
            if value != nil
              if value.is_a?(Array) || value.is_a?(OSX::NSArray)
                unless value.empty?
                  indexes = OSX::NSIndexSet.indexSetWithIndexesInRange(NSRange.new(n, value.length))
                  insertObjects_atIndexes(value, indexes)
                end
              else
                insertObject_atIndex(value, n)
              end
            end
          else
            if value != nil
              if value.is_a?(Array) || value.is_a?(OSX::NSArray)
                unless value.empty?
                  addObjectsFromArray(value)
                end
              else
                addObject(value)
              end
            end
          end
          value
        else
          raise ArgumentError, "wrong number of arguments (#{args.length} for 3)"
        end
      when 3
        n, len, value = args
        unless n.is_a?(Numeric) || n.is_a?(OSX::NSNumber)
          raise TypeError, "can't convert #{n.class} into Integer"
        end
        unless len.is_a?(Numeric) || len.is_a?(OSX::NSNumber)
          raise TypeError, "can't convert #{len.class} into Integer"
        end
        n = n.to_i
        len = len.to_i
        n += count if n < 0
        if n < 0 || count < n
          raise IndexError, "index #{args[0]} out of array"
        end
        if len < 0
          raise IndexError, "negative length (#{len})"
        end
        self[n...n+len] = value
      else
        raise ArgumentError, "wrong number of arguments (#{args.length} for 3)"
      end
    end

    def <<(obj)
      addObject(obj)
      self
    end

    def &(other)
      ary = other
      unless ary.is_a?(Array) || ary.is_a?(OSX::NSArray)
        if ary.respond_to?(:to_ary)
          ary = ary.to_ary
          unless ary.is_a?(Array) || ary.is_a?(OSX::NSArray)
            raise TypeError, "can't convert #{other.class} into Array"
          end
        else
          raise TypeError, "can't convert #{other.class} into Array"
        end
      end
      result = [].to_ns
      dic = {}.to_ns
      each {|i| dic.setObject_forKey(i, i) }
      ary.each do |i|
        if dic.objectForKey(i)
          result.addObject(i)
          dic.removeObjectForKey(i)
        end
      end
      result
    end

    def |(other)
      ary = other
      unless ary.is_a?(Array) || ary.is_a?(OSX::NSArray)
        if ary.respond_to?(:to_ary)
          ary = ary.to_ary
          unless ary.is_a?(Array) || ary.is_a?(OSX::NSArray)
            raise TypeError, "can't convert #{other.class} into Array"
          end
        else
          raise TypeError, "can't convert #{other.class} into Array"
        end
      end
      result = [].to_ns
      dic = {}.to_ns
      [self, ary].each do |obj|
        obj.each do |i|
          unless dic.objectForKey(i)
            dic.setObject_forKey(i, i)
            result.addObject(i)
          end
        end
      end
      result
    end

    def *(arg)
      case arg
      when Numeric
        (to_a * arg).to_ns
      when String
        join(arg)
      else
        raise TypeError, "can't convert #{arg.class} into Integer"
      end
    end

    def +(other)
      ary = other
      unless ary.is_a?(Array) || ary.is_a?(OSX::NSArray)
        if ary.respond_to?(:to_ary)
          ary = ary.to_ary
          unless ary.is_a?(Array) || ary.is_a?(OSX::NSArray)
            raise TypeError, "can't convert #{other.class} into Array"
          end
        else
          raise TypeError, "can't convert #{other.class} into Array"
        end
      end
      result = mutableCopy
      result.addObjectsFromArray(other)
      result
    end

    def -(other)
      ary = other
      unless ary.is_a?(Array) || ary.is_a?(OSX::NSArray)
        if ary.respond_to?(:to_ary)
          ary = ary.to_ary
          unless ary.is_a?(Array) || ary.is_a?(OSX::NSArray)
            raise TypeError, "can't convert #{other.class} into Array"
          end
        else
          raise TypeError, "can't convert #{other.class} into Array"
        end
      end
      result = [].to_ns
      dic = {}.to_ns
      ary.each {|i| dic.setObject_forKey(i, i) }
      each {|i| result.addObject(i) unless dic.objectForKey(i) }
      result
    end

    def assoc(key)
      each do |i|
        if i.is_a? OSX::NSArray
          unless i.empty?
            return i if i.first.isEqual(key)
          end
        end
      end
      nil
    end

    def at(pos)
      self[pos]
    end

    def clear
      removeAllObjects
      self
    end

    def collect!
      copy.each_with_index {|i,n| replaceObjectAtIndex_withObject(n, (yield i)) }
      self
    end
    alias_method :map!, :collect!

    # does nothing because NSArray cannot have nil
    def compact; mutableCopy; end
    def compact!; nil; end

    def concat(other)
      addObjectsFromArray(other)
      self
    end

    def delete(val)
      indexes = OSX::NSMutableIndexSet.indexSet
      each_with_index {|i,n| indexes.addIndex(n) if i.isEqual(val) }
      removeObjectsAtIndexes(indexes) if indexes.count > 0
      if indexes.count > 0
        val
      else
        if block_given?
          yield
        end
        nil
      end
    end

    def delete_at(pos)
      unless pos.is_a? Numeric
        raise TypeError, "can't convert #{pos.class} into Integer"
      end
      count = self.count
      pos = pos.to_i
      pos += count if pos < 0
      if 0 <= pos && pos < count
        result = self[pos]
        removeObjectAtIndex(pos)
        result
      else
        nil
      end
    end

    def delete_if(&block)
      reject!(&block)
      self
    end

    def reject!
      indexes = OSX::NSMutableIndexSet.indexSet
      each_with_index {|i,n| indexes.addIndex(n) if yield i }
      if indexes.count > 0
        removeObjectsAtIndexes(indexes)
        self
      else
        nil
      end
    end

    def each_index
      each_with_index {|i,n| yield n }
    end

    def empty?
      count == 0
    end

    def fetch(*args)
      count = self.count
      len = args.length
      if len == 0 || len > 2
        raise ArgumentError, "wrong number of arguments (#{len} for 2)"
      end
      index = args.first
      unless index.is_a? Numeric
        raise TypeError, "can't convert #{index.class} into Integer"
      end
      index = index.to_i
      index += count if index < 0
      if 0 <= index && index < count
        objectAtIndex(index)
      else
        if len == 2
          args[1]
        elsif block_given?
          yield
        else
          raise IndexError, "index #{args.first} out of array"
        end
      end
    end

    def fill(*args, &block)
      count = self.count
      len = args.length
      len -= 1 unless block
      case len
      when 0
        val = args.first
        n = -1
        map! do |i|
          n += 1
          block ? block.call(n) : val
        end
      when 1
        if block
          first = args.first
        else
          val, first = args
        end
        case first
        when Numeric
          start = first.to_i
          start += count if start < 0
          n = -1
          map! do |i|
            n += 1
            if start <= n
              block ? block.call(n) : val
            else
              i
            end
          end
        when Range
          range = first
          left, len, right = OSX::RangeUtil.normalize(range, count)
          if left < 0 || count < left
            raise RangeError, "#{range} out of range"
          end
          n = -1
          map! do |i|
            n += 1
            if left <= n && n < right
              block ? block.call(n) : val
            else
              i
            end
          end
          (n+1).upto(right-1) do |i|
            n += 1
            addObject(block ? block.call(n) : val)
          end
          self
        else
          raise TypeError, "can't convert #{first.class} into Integer"
        end
      when 2
        if block
          first, len = args
        else
          val, first, len = args
        end
        start = first
        unless start.is_a? Numeric
          raise TypeError, "can't convert #{start.class} into Integer"
        end
        unless len.is_a? Numeric
          raise TypeError, "can't convert #{len.class} into Integer"
        end
        start = start.to_i
        len = len.to_i
        start += count if start < 0
        if start < 0 || count < start
          raise IndexError, "index #{first} out of array"
        end
        len = 0 if len < 0
        if block
          fill(start...start+len, &block)
        else
          fill(val, start...start+len)
        end
      else
        raise ArgumentError, "wrong number of arguments (#{args.length} for 2)"
      end
    end

    def first(n=nil)
      if n
        if n.is_a? Numeric
          len = n.to_i
          if len < 0
            raise ArgumentError, "negative array size (or size too big)"
          end
          self[0...n]
        else
          raise TypeError, "can't convert #{n.class} into Integer"
        end
      else
        self[0]
      end
    end

    def flatten
      result = [].to_ns
      each do |i|
        if i.is_a? OSX::NSArray
          result.addObjectsFromArray(i.flatten)
        else
          result.addObject(i)
        end
      end
      result
    end

    def flatten!
      flat = true
      result = [].to_ns
      each do |i|
        if i.is_a? OSX::NSArray
          flat = false
          result.addObjectsFromArray(i.flatten)
        else
          result.addObject(i)
        end
      end
      if flat
        nil
      else
        setArray(result)
        self
      end
    end

    def include?(val)
      index(val) != nil
    end

    def index(*args)
      if block_given?
        each_with_index {|i,n| return n if yield i}
      elsif args.length == 1
        val = args.first
        each_with_index {|i,n| return n if i.isEqual(val)}
      else
        raise ArgumentError, "wrong number of arguments (#{args.length} for 1)"
      end
      nil
    end

    def insert(n, *vals)
      if n == -1
        push(*vals)
      else
        n += count + 1 if n < 0
        self[n, 0] = vals
      end
      self
    end

    def join(sep=$,)
      s = ''
      each do |i|
        s += sep if sep && !s.empty?
        if i == self
          s << '[...]'
        elsif i.is_a? OSX::NSArray
          s << i.join(sep)
        else
          s << i.to_s
        end
      end
      s
    end

    def last(n=nil)
      if n
        if n.is_a? Numeric
          len = n.to_i
          if len < 0
            raise ArgumentError, "negative array size (or size too big)"
          end
          if len == 0
            [].to_ns
          elsif len >= count
            mutableCopy
          else
            self[(-len)..-1]
          end
        else
          raise TypeError, "can't convert #{n.class} into Integer"
        end
      else
        self[-1]
      end
    end

    def pack(template)
      to_ruby.pack(template)
    end

    def pop
      if count > 0
        result = lastObject
        removeLastObject
        result
      else
        nil
      end
    end

    def push(*args)
      case args.length
      when 0
        ;
      when 1
        addObject(args.first)
      else
        addObjectsFromArray(args)
      end
      self
    end

    def rassoc(key)
      each do |i|
        if i.is_a? OSX::NSArray
          if i.count >= 1
            return i if i[1].isEqual(key)
          end
        end
      end
      nil
    end

    def replace(another)
      setArray(another)
      self
    end

    def reverse
      to_a.reverse.to_ns
    end

    def reverse!
      setArray(to_a.reverse)
      self
    end

    def rindex(*args)
      if block_given?
        n = count
        reverse_each do |i|
          n -= 1
          return n if yield i
        end
      elsif args.length == 1
        val = args.first
        n = count
        reverse_each do |i|
          n -= 1
          return n if i.isEqual(val)
        end
      else
        raise ArgumentError, "wrong number of arguments (#{args.length} for 1)"
      end
      nil
    end

    def shift
      unless empty?
        result = objectAtIndex(0)
        removeObjectAtIndex(0)
        result
      else
        nil
      end
    end

    def count
      oc_count
    end

    def size
      count
    end
    alias_method :length, :size
    alias_method :nitems, :size

    def slice!(*args)
      _read_impl(:slice!, args)
    end

    def sort!(&block)
      setArray(to_a.sort(&block))
      self
    end

    def to_splat
      to_a
    end

    def transpose
      to_a.transpose.to_ns
    end

    def uniq
      result = [].to_ns
      dic = {}.to_ns
      each do |i|
        unless dic.has_key?(i)
          dic.setObject_forKey(i, i)
          result.addObject(i)
        end
      end
      result
    end

    def uniq!
      if empty?
        nil
      else
        dic = {}.to_ns
        indexes = OSX::NSMutableIndexSet.indexSet
        each_with_index do |i,n|
          if dic.has_key?(i)
            indexes.addIndex(n)
          else
            dic.setObject_forKey(i, i)
          end
        end
        if indexes.count > 0
          removeObjectsAtIndexes(indexes)
          self
        else
          nil
        end
      end
    end

    def unshift(*args)
      if count == 0
        push(*args)
      else
        case args.length
        when 0
          ;
        when 1
          insertObject_atIndex(args.first, 0)
        else
          indexes = OSX::NSIndexSet.indexSetWithIndexesInRange(NSRange.new(0, args.length))
          insertObjects_atIndexes(args, indexes)
        end
        self
      end
    end

    def values_at(*indexes)
      indexes.map {|i| self[i]}.to_ns
    end
    alias_method :indexes, :values_at
    alias_method :indices, :values_at

    def inspect
      "#<#{self.class.to_s.gsub(/^OSX::/, '')} #{ self.to_a.inspect }>"
    end

    def pretty_print(q)
      self.to_a.pretty_print(q)
    end

    private

    def _read_impl(method, args)
      slice = method == :slice!
      count = self.count
      case args.length
      when 1
        first = args.first
        case first
        when Numeric,OSX::NSNumber
	  _read_impl_num(slice, first.to_i, count)
        when Range
	  _read_impl_range(slice, first, count)
        else
          raise TypeError, "can't convert #{args.first.class} into Integer"
        end
      when 2
        n, len = args
        unless n.is_a?(Numeric) || n.is_a?(OSX::NSNumber)
          raise TypeError, "can't convert #{n.class} into Integer"
        end
        unless len.is_a?(Numeric) || len.is_a?(OSX::NSNumber)
          raise TypeError, "can't convert #{len.class} into Integer"
        end
	_read_impl_num_len(slice, method, n.to_i, len.to_i, count)
      else
        raise ArgumentError, "wrong number of arguments (#{args.length} for 2)"
      end
    end

    def _read_impl_num(slice, num, count)
      num += count if num < 0
      if 0 <= num && num < count
	result = objectAtIndex(num)
	removeObjectAtIndex(num) if slice
	result
      else
	nil
      end
    end

    def _read_impl_range(slice, range, count)
      n, len = OSX::RangeUtil.normalize(range, count)
      if n < 0 || count < n
	return nil
      end
      
      if 0 <= n && n < count
	nsrange = OSX::NSRange.new(n, len)
	indexes = OSX::NSIndexSet.indexSetWithIndexesInRange(nsrange)
	result = objectsAtIndexes(indexes).mutableCopy
	removeObjectsAtIndexes(indexes) if slice
	result
      else
	[].to_ns
      end
    end

    def _read_impl_num_len(slice, method, num, len, count)
      if len < 0
	nil
      else
	num += count if num < 0
	if num < 0
	  nil
	else
	  _read_impl(method, [num...num+len])
	end
      end
    end

    # the behavior of Array#slice is different from 1.8.6 or earlier
    # against an out of range argument
    if RUBY_VERSION <= '1.8.6'
      def _read_impl_range(slice, range, count)
	n, len = OSX::RangeUtil.normalize(range, count)
	if n < 0 || count < n
	  if slice
	    # raises RangeError, 1.8.7 or later returns nil
	    raise RangeError, "#{first} out of range" 
	  end
	  return nil
	end
	
	if 0 <= n && n < count
	  nsrange = OSX::NSRange.new(n, len)
	  indexes = OSX::NSIndexSet.indexSetWithIndexesInRange(nsrange)
	  result = objectsAtIndexes(indexes).mutableCopy
	  removeObjectsAtIndexes(indexes) if slice
	  result
	else
	  [].to_ns
	end
      end

      def _read_impl_num_len(slice, method, num, len, count)
	if len < 0
	  if slice
	    # raises IndexError, 1.8.7 or later returns nil
	    raise IndexError, "negative length (#{len})"
	  end
	  nil
	else
	  num += count if num < 0
	  if num < 0
	    nil
	  else
	    _read_impl(method, [num...num+len])
	  end
	end
    end

    end
  end

  class NSArray
    include NSEnumerable
  end

  # NSDictionary additions
  class NSDictionary
    include OSX::OCObjWrapper

    def dup
      mutableCopy
    end
    
    def clone
      obj = dup
      obj.freeze if frozen?
      obj.taint if tainted?
      obj
    end
    
    # enable to treat as Hash
    def to_hash
      h = {}
      each {|k,v| h[k] = v }
      h
    end
    
    # comparison between Ruby Hash and Cocoa NSDictionary
    def ==(other)
      if other.is_a? OSX::NSDictionary
        isEqualToDictionary?(other)
      elsif other.respond_to? :to_hash
        to_hash == other.to_hash
      else
        false
      end
    end

    def <=>(other)
      if other.respond_to? :to_hash
        to_hash <=> other.to_hash
      else
        nil
      end
    end
    
    # For NSDictionary duck typing
    def each
      iter = keyEnumerator
      while key = iter.nextObject
        yield [key, objectForKey(key)]
      end
      self
    end

    def each_pair
      iter = keyEnumerator
      while key = iter.nextObject
        yield key, objectForKey(key)
      end
      self
    end

    def each_key
      iter = keyEnumerator
      while key = iter.nextObject
        yield key
      end
      self
    end

    def each_value
      iter = objectEnumerator
      while obj = iter.nextObject
        yield obj
      end
      self
    end

    def [](key)
      result = objectForKey(key)
      if result
        result
      else
        default(key)
      end
    end

    def []=(key, obj)
      setObject_forKey(obj, key)
      obj
    end
    alias_method :store, :[]=

    def clear
      removeAllObjects
      self
    end

    def default(*args)
      if args.length <= 1
        if @default_proc
          @default_proc.call(self, args.first)
        elsif @default
          @default
        else
          nil
        end
      else
        raise ArgumentError, "wrong number of arguments (#{args.length} for 2)"
      end
    end

    def default=(value)
      @default = value
    end

    def default_proc
      @default_proc
    end

    def default_proc=(value)
      @default_proc = value
    end

    def delete(key)
      obj = objectForKey(key)
      if obj
        removeObjectForKey(key)
        obj
      else
        if block_given?
          yield key
        else
          nil
        end
      end
    end

    def delete_if(&block)
      reject!(&block)
      self
    end

    def fetch(key, *args)
      result = objectForKey(key)
      if result
        result
      else
        if args.length > 0
          args.first
        elsif block_given?
          yield key
        else
          raise IndexError, "key not found"
        end
      end
    end

    def reject!
      keys = [].to_ns
      each {|key,value| keys.addObject(key) if yield key, value }
      if keys.count > 0
        removeObjectsForKeys(keys)
        self
      else
        nil
      end
    end

    def empty?
      count == 0
    end

    def has_key?(key)
      objectForKey(key) != nil
    end
    alias_method :include?, :has_key?
    alias_method :key?, :has_key?
    alias_method :member?, :has_key?

    def has_value?(value)
      each_value {|i| return true if i.isEqual?(value) }
      false
    end
    alias_method :value?, :has_value?

    def invert
      dic = {}.to_ns
      each_pair {|key,value| dic[value] = key }
      dic
    end

    def key(val)
      each_pair {|key,value| return key if value.isEqual?(val) }
      nil
    end

    def keys
      allKeys
    end

    def merge(other, &block)
      dic = mutableCopy
      dic.merge!(other, &block)
      dic
    end

    def merge!(other)
      if block_given?
        other.each do |key,value|
          if mine = objectForKey(key)
            setObject_forKey((yield key, mine, value), key)
          else
            setObject_forKey(value,key)
          end
        end
      else
        other.each {|key,value| setObject_forKey(value, key) }
      end
      self
    end
    alias_method :update, :merge!

    def shift
      if empty?
        default
      else
        key = allKeys.objectAtIndex(0)
        value = objectForKey(key)
        removeObjectForKey(key)
        [key, value].to_ns
      end
    end

    def count
      oc_count
    end
    def size
      count
    end
    alias_method :length, :size

    def rehash; self; end

    def reject(&block)
      to_hash.delete_if(&block)
    end

    def replace(other)
      setDictionary(other)
      self
    end

    def values
      allValues
    end

    def values_at(*args)
      result = []
      args.each do |k|
        if v = objectForKey(k)
          result << v
        else
          result << default
        end
      end
      result.to_ns
    end
    
    def inspect
      "#<#{self.class.to_s.gsub(/^OSX::/, '')} #{ self.to_hash.inspect }>"
    end
    
    def pretty_print(q)
      self.to_hash.pretty_print(q)
    end
  end
  class NSDictionary
    include NSEnumerable
  end

  class NSUserDefaults
    def [] (key)
      self.objectForKey(key)
    end

    def []= (key, obj)
      self.setObject_forKey(obj, key)
    end

    def delete (key)
      self.removeObjectForKey(key)
    end
  end

  # NSData additions
  class NSData
    def rubyString
      cptr = self.bytes
      return cptr.bytestr( self.length )
    end
  end

  # NSIndexSet additions
  class NSIndexSet
    def to_a
      result = []
      index = self.firstIndex
      until index == OSX::NSNotFound
        result << index
        index = self.indexGreaterThanIndex(index)
      end
      return result
    end
    
    def inspect
      "#<#{self.class.to_s.gsub(/^OSX::/, '')} #{ self.to_a.inspect }>"
    end
  end

  # NSSelectionArray additions
  class NSSelectionArray
    # workdaround for Tiger
    def to_a
      ary = []
      (0...count).each {|i| ary << objectAtIndex(i) }
      ary
    end
  end

  # NSEnumerator additions
  class NSEnumerator
    def to_a
      self.allObjects.to_a
    end
  end

  # NSNumber additions
  class NSNumber
    def to_i
      self.stringValue.to_s.to_i
    end

    def to_f
      self.doubleValue
    end
    
    def float?
      warn "#{caller[0]}: 'NSNumber#float?' is now deprecated and its use is discouraged, please use integer? instead."
      OSX::CFNumberIsFloatType(self)
    end
    
    def integer?
      !OSX::CFNumberIsFloatType(self)
    end
    
    def ==(other)
      if other.is_a? NSNumber
        isEqualToNumber?(other)
      elsif other.is_a? Numeric
        if integer?
          to_i == other
        else
          to_f == other
        end
      else
        false
      end
    end

    def <=>(other)
      if other.is_a? NSNumber
        compare(other)
      elsif other.is_a? Numeric
        if integer?
          to_i <=> other
        else
          to_f <=> other
        end
      else
        nil
      end
    end
    
    def inspect
      "#<#{self.class.to_s.gsub(/^OSX::/, '')} #{self.description}>"
    end
  end

  # NSCFBoolean additions
  class NSCFBoolean
    def inspect
      "#<#{self.class.to_s.gsub(/^OSX::/, '')} #{ (self == 1) ? true : false }>"
    end
  end

  # NSDate additions
  class NSDate
    def to_time
      Time.at(self.timeIntervalSince1970)
    end
    def inspect
      "#<#{self.class.to_s.gsub(/^OSX::/, '')} #{self.description}>"
    end
  end

  # NSObject additions
  class NSObject
    def to_ruby
      case self 
      when OSX::NSDate
        self.to_time
      when OSX::NSCFBoolean
        self.boolValue
      when OSX::NSNumber
        self.integer? ? self.to_i : self.to_f
      when OSX::NSString
        self.to_s
      when OSX::NSAttributedString
        self.string.to_s
      when OSX::NSArray
        self.to_a.map { |x| x.is_a?(OSX::NSObject) ? x.to_ruby : x }
      when OSX::NSDictionary
        h = {}
        self.each do |x, y| 
          x = x.to_ruby if x.is_a?(OSX::NSObject)
          y = y.to_ruby if y.is_a?(OSX::NSObject)
          h[x] = y
        end
        h
      else
        self
      end
    end
  end
end

OSX._ignore_ns_override = false
