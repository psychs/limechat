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
      @other.filename = Pathname.new(fullname + '.yaml')
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
  attr_reader :input_text_color, :input_text_bgcolor, :input_text_font
  attr_reader :tree_highlight_color, :tree_newtalk_color, :tree_unread_color, :tree_font
  attr_reader :member_list_font, :member_list_color, :member_list_bgcolor
  attr_reader :member_list_op_color
  
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
  ensure
    update
  end
  
  private
  
  def update
    @input_text_font = load_font('input-text') || NSFont.systemFontOfSize(-1)
    @input_text_bgcolor = load_color('input-text', 'background-color') || NSColor.whiteColor
    @input_text_color = load_color('input-text', 'color') || NSColor.blackColor
    
    @tree_font = load_font('server-tree') || NSFont.systemFontOfSize(-1)
    @tree_highlight_color = load_color('server-tree', 'highlight', 'color') || NSColor.magentaColor
    @tree_newtalk_color = load_color('server-tree', 'newtalk', 'color') || NSColor.redColor
    @tree_unread_color = load_color('server-tree', 'unread', 'color') || NSColor.blueColor
    
    @member_list_font = load_font('member-list') || NSFont.systemFontOfSize(-1)
    @member_list_bgcolor = load_color('member-list', 'background-color') || NSColor.whiteColor
    @member_list_color = load_color('member-list', 'color') || NSColor.blackColor
    @member_list_op_color = load_color('member-list', 'operator', 'color') || NSColor.blackColor
  end
  
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
  
  def load_color(category, *keys)
    return nil unless @content
    config = @content[category]
    return nil unless config
    keys.each do |i|
      config = config[i]
      return nil unless config
    end
    NSColor.from_css(config)
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
