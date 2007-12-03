# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'pathname'
require 'utility'

class LogTheme
  attr_reader :name, :base

  RESOURCE_BASE = '~/Library/Application Support/LimeChat/Theme'.expand_path
  USER_BASE = '~/Library/Application Support/LimeChat/Theme'.expand_path
  
  def initialize(name)
    self.theme = name
  end
  
  def theme=(name)
    if name
      @name = name.dup
      name =~ /\A(\w+):(.*)\z/
      kind = $1
      fname = $2
      
      if kind == 'resource'
        fullname = "#{RESOURCE_BASE}/#{fname}.css"
      else
        fullname = "#{USER_BASE}/#{fname}.css"
      end
      @filename = Pathname.new(fullname).expand_path
      @base = OSX::NSURL.fileURLWithPath(@filename.dirname.to_s)
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
