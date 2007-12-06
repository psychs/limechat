# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'pathname'
require 'utility'

class LogTheme
  attr_reader :name, :base
  
  RESOURCE_BASE = (Pathname.new(NSBundle.mainBundle.resourcePath.fileSystemRepresentation).parent.expand_path + 'Theme').to_s
  USER_BASE = '~/Library/LimeChat/Theme'.expand_path
  
  def self.RESOURCE_BASE
    RESOURCE_BASE
  end
  
  def self.USER_BASE
    USER_BASE
  end
  
  def self.extract_name(name)
    if name =~ /\A(\w+):(.*)\z/
      [$1, $2]
    else
      nil
    end
  end
  
  def self.resource_filename(fname)
    "resource:#{fname}"
  end
  
  def self.user_filename(fname)
    "user:#{fname}"
  end
  
  def initialize(name)
    self.theme = name
  end
  
  def theme=(name)
    if name
      @name = name.dup
      kind, fname = LogTheme.extract_name(name)
      if kind == 'resource'
        fullname = "#{RESOURCE_BASE}/#{fname}.css"
      else
        fullname = "#{USER_BASE}/#{fname}.css"
      end
      @filename = Pathname.new(fullname).expand_path
      @base = NSURL.fileURLWithPath(@filename.dirname.to_s)
      reload
    else
      @name = ''
      @filename = nil
      @base = nil
    end
  end
  
  def content
    @content || ''
  end
  
  def reload
    @content = nil
    return false unless @filename && @filename.exist?
    prev = @content
    @filename.open {|f| @content = f.read }
    prev != @content
  rescue
    ;
  end
end
