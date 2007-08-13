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
    s = s.gsub(/[\[\]\{\}\(\)\|\-\*\.\\\?\+\^\$ \#\t\f\n\r]/) {|i|
      case i
      when ' '; '\ '
      when "\t"; '\t'
      when "\n"; '\n'
      when "\r"; '\r'
      when "\f"; '\f'
      when '*'; '.*'
      when '?'; '.?'
      else; '\\' + i
      end
    }
    '\A' + s + '\z'
  end
end
