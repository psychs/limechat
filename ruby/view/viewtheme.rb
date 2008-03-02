# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'pathname'
require 'yaml'
require 'utility'

class ViewTheme
  
  RESOURCE_BASE = (Pathname.new(NSBundle.mainBundle.resourcePath.fileSystemRepresentation).parent.expand_path + 'Themes').to_s
  USER_BASE = '~/Library/LimeChat/Themes'.expand_path
  
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
  attr_reader :log_nick_format, :log_scroller_highlight_color
  attr_reader :input_text_font, :input_text_color, :input_text_bgcolor
  attr_reader :tree_font, :tree_bgcolor, :tree_highlight_color, :tree_newtalk_color, :tree_unread_color
  attr_reader :tree_active_color, :tree_inactive_color, :tree_sel_active_color, :tree_sel_inactive_color
  attr_reader :tree_sel_top_line_color, :tree_sel_bottom_line_color, :tree_sel_top_color, :tree_sel_bottom_color
  attr_reader :member_list_font, :member_list_color, :member_list_bgcolor
  attr_reader :member_list_op_color
  attr_reader :member_list_sel_color, :member_list_sel_top_line_color, :member_list_sel_bottom_line_color
  attr_reader :member_list_sel_top_color, :member_list_sel_bottom_color

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
    @content = nil
    false
  ensure
    update
  end
  
  private
  
  def update
    @log_nick_format = load_string('log-view', 'nickname-format') || '%n: '
    @log_scroller_highlight_color = load_color('log-view', 'scroller-highlight-color') || NSColor.magentaColor
    
    @input_text_font = load_font('input-text') || NSFont.systemFontOfSize(-1)
    @input_text_bgcolor = load_color('input-text', 'background-color') || NSColor.whiteColor
    @input_text_color = load_color('input-text', 'color') || NSColor.blackColor
    
    @tree_font = load_font('server-tree') || NSFont.systemFontOfSize(-1)
    @tree_bgcolor = load_color('server-tree', 'background-color') || NSColor.from_rgb(229, 237, 247)
    @tree_highlight_color = load_color('server-tree', 'highlight', 'color') || NSColor.magentaColor
    @tree_newtalk_color = load_color('server-tree', 'newtalk', 'color') || NSColor.redColor
    @tree_unread_color = load_color('server-tree', 'unread', 'color') || NSColor.blueColor
    
    @tree_active_color = load_color('server-tree', 'normal', 'active', 'color') || NSColor.blackColor
    @tree_inactive_color = load_color('server-tree', 'normal', 'inactive', 'color') || NSColor.lightGrayColor
    
    @tree_sel_active_color = load_color('server-tree', 'selected', 'active', 'color') || NSColor.blackColor
    @tree_sel_inactive_color = load_color('server-tree', 'selected', 'inactive', 'color') || NSColor.grayColor    
    @tree_sel_top_line_color = load_color('server-tree', 'selected', 'background', 'top-line-color') || NSColor.from_rgb(173, 187, 208)
    @tree_sel_bottom_line_color = load_color('server-tree', 'selected', 'background', 'bottom-line-color') || NSColor.from_rgb(140, 152, 176)
    @tree_sel_top_color = load_color('server-tree', 'selected', 'background', 'top-color') || NSColor.from_rgb(173, 187, 208)
    @tree_sel_bottom_color = load_color('server-tree', 'selected', 'background', 'bottom-color') || NSColor.from_rgb(152, 170, 196)
    
    @member_list_font = load_font('member-list') || NSFont.systemFontOfSize(-1)
    @member_list_bgcolor = load_color('member-list', 'background-color') || NSColor.whiteColor
    @member_list_color = load_color('member-list', 'color') || NSColor.blackColor
    @member_list_op_color = load_color('member-list', 'operator', 'color') || NSColor.blackColor
    
    @member_list_sel_color = load_color('member-list', 'selected', 'color')
    @member_list_sel_top_line_color = load_color('member-list', 'selected', 'background', 'top-line-color')
    @member_list_sel_bottom_line_color = load_color('member-list', 'selected', 'background', 'bottom-line-color')
    @member_list_sel_top_color = load_color('member-list', 'selected', 'background', 'top-color')
    @member_list_sel_bottom_color = load_color('member-list', 'selected', 'background', 'bottom-color')
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
  rescue
    nil
  end
  
  def load_color(category, *keys)
    s = load_string(category, *keys)
    return nil unless s
    NSColor.from_css(s)
  end
  
  def load_string(category, *keys)
    return nil unless @content
    config = @content[category]
    return nil unless config
    keys.each do |i|
      config = config[i]
      return nil unless config
    end
    config
  rescue
    nil
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
