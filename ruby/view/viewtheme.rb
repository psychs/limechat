# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'pathname'
require 'yaml'
require 'utility'

class ViewTheme
  
  RESOURCE_BASE = (Pathname.new(NSBundle.mainBundle.resourcePath.fileSystemRepresentation).parent.expand_path + 'Theme').to_s
  USER_BASE = '~/Library/LimeChat/Theme'.expand_path
  
  def self.RESOURCE_BASE; RESOURCE_BASE; end
  def self.USER_BASE; USER_BASE; end
  
  def self.resource_filename(fname); "resource:#{fname}"; end
  def self.user_filename(fname); "user:#{fname}"; end
  
  def self.extract_name(name)
    if name =~ /\A([a-z]+):(.*)\z/
      [$1, $2]
    else
      nil
    end
  end
  
  
  attr_reader :name, :log, :other
  
  def initialize(name)
    @log = LogTheme.new
    @other = OtherViewTheme.new
    self.theme = name
  end
  
  def theme=(name)
    if name
      @name = name.dup
      kind, fname = ViewTheme.extract_name(@name)
      if kind == 'resource'
        fullname = "#{RESOURCE_BASE}/#{fname}"
      else
        fullname = "#{USER_BASE}/#{fname}"
      end
      @log.filename = Pathname.new(fullname + '.css')
      @other.filename = Pathname.new(fullname + '.yml')
    else
      @name = ''
      @log.filename = nil
      @other.filename = nil
    end
  end
  
  def reload
    @log.reload
    @other.reload
  end
end


class OtherViewTheme
  def filename=(fname)
    if fname
      @filename = fname
      reload
    else
      @filename = nil
      @content = nil
    end
  end
  
  def reload
    @content = nil
    return false unless @filename && @filename.exist?
    prev = @content
    @content = YAML.load(@filename.open)
    prev != @content
  rescue
    false
  end
  
  def input_text_color
    load_color('input-text', 'color')
  end
  
  def input_text_background_color
    load_color('input-text', 'background-color')
  end
  
  def input_text_font
    load_font('input-text')
  end
  
  private
  
  def load_font(category)
    return nil unless @content
    config = @content[category]
    return nil unless config
    family = config['font-family']
    size = config['font-size']
    weight = config['font-weight']
    style = config['font-style']
    size = NSFont.systemFontSize unless size
    if family
      font = NSFont.fontWithName_size(family, size)
    else
      font = NSFont.systemFontOfSize(size)
    end
    font = NSFont.systemFontOfSize(-1) unless font
    fm = NSFontManager.sharedFontManager
    if weight == 'bold'
      to = fm.convertFont_toHaveTrait(font, NSBoldFontMask)
      font = to if to
    end
    if style == 'italic'
      to = fm.convertFont_toHaveTrait(font, NSItalicFontMask)
      font = to if to
    end
    font
  end
  
  def load_color(category, key)
    return nil unless @content
    config = @content[category]
    return nil unless config
    to_color(config[key])
  end
  
  def to_color(str)
    return nil unless str
    if str =~ /\A#/
      str[0] = ''
      case str.size
      when 6
        r = str[0..1].to_i(16)
        g = str[2..3].to_i(16)
        b = str[4..5].to_i(16)
        NSColor.colorWithCalibratedRed_green_blue_alpha(r/255.0, g/255.0, b/255.0, 1.0)
      when 3
        r = str[0..0].to_i(16)
        g = str[1..1].to_i(16)
        b = str[2..2].to_i(16)
        NSColor.colorWithCalibratedRed_green_blue_alpha(r/15.0, g/15.0, b/15.0, 1.0)
      else
        nil
      end
    else
      nil
    end
  end
end


class LogTheme
  attr_reader :content, :baseurl
  
  def filename=(fname)
    if fname
      @filename = fname
      @baseurl = NSURL.fileURLWithPath(@filename.dirname.to_s)
      reload
    else
      @filename = nil
      @baseurl = nil
      @content = nil
    end
  end
  
  def reload
    @content = nil
    return false unless @filename && @filename.exist?
    prev = @content
    @filename.open {|f| @content = f.read }
    prev != @content
  rescue
    false
  end
end
