# Copyright (c) 2006-2008, The RubyCocoa Project.
# Copyright (c) 2001-2006, FUJIMOTO Hisakuni.
# All Rights Reserved.
#
# RubyCocoa is free software, covered under either the Ruby's license or the 
# LGPL. See the COPYRIGHT file for more information.

# Same as oc_types but AppKit-specific.

class OSX::NSRange
  class << self
    alias_method :orig_new, :new
    def new(*args)
      location, length = case args.size
      when 0
        [0, 0]
      when 1
        if args.first.is_a?(Range)
          range = args.first
          [range.first, range.last - range.first + (range.exclude_end? ? 0 : 1)]
        else
          raise ArgumentError, "wrong type of argument #1 (expected Range, got #{args.first.class})"
        end
      when 2
        if args.first.is_a?(Range)
          range, count = args
          first = range.first
          first += count if first < 0
          last = range.last
          last += count if last < 0
          len = last - first + (range.exclude_end? ? 0 : 1)
          len = count - first if count < first + len
          len = 0 if len < 0
          [first, len]
        else
          [args[0], args[1]]
        end
      else
        raise ArgumentError, "wrong number of arguments (#{args.size} for either 0, 1 or 2)"
      end
      orig_new(location, length)
    end
  end
  def to_range
    Range.new(location, location + length, true)
  end
  def size; length; end
  def size=(v); length = v; end
  def contain?(arg)
    case arg
    when OSX::NSRange
      location <= arg.location and arg.location + arg.length <= location + length
    when Numeric
      OSX::NSLocationInRange(arg, self)
    else
      raise ArgumentError, "argument should be NSRange or Numeric"
    end
  end
  def empty?; length == 0 || not_found?; end
  def intersect?(range); !intersection(range).empty?; end
  def intersection(range); OSX::NSIntersectionRange(self, range); end
  def union(range); OSX::NSUnionRange(self, range); end
  def max; location + length; end
  def not_found?; location == OSX::NSNotFound; end
  def inspect; "#<#{self.class} location=#{location}, length=#{length}>"; end
end
