# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

class Wildcard < Regexp
  attr_reader :pattern
  
  def initialize(*args)
    @pattern = args.shift
    super(to_wildcard(@pattern), *args)
  end
  
  def to_s
    @pattern
  end
  
  private
  
  def to_wildcard(s)
    '\A' + Regexp.escape(s).gsub(/\\\*/, '.*').gsub(/\\\?/, '.') + '\z'
  end
end
