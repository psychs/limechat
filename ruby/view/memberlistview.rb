# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'user'

class MemberListViewCell < NSCell
  attr_writer :member
  
  class << self
    attr_reader :theme, :mark_style, :nick_style, :mark_width
    
    def theme=(theme)
      @mark_width = 0
      @theme = theme
      @mark_style = NSMutableParagraphStyle.alloc.init
      @mark_style.setAlignment(NSCenterTextAlignment)
      @nick_style = NSMutableParagraphStyle.alloc.init
      @nick_style.setAlignment(NSLeftTextAlignment)
      @nick_style.setLineBreakMode(NSLineBreakByTruncatingTail)
    end
    
    def calculate_mark_width(cell)
      @mark_width = 0
      User.marks.each do |s|
        n = s.to_ns.sizeWithAttributes(NSFontAttributeName => cell.font)
        @mark_width = n.width if n.width > @mark_width
      end
    end
  end
  
  def setup(theme)
    self.class.theme = theme
  end
  
  def themeChanged
    self.class.calculate_mark_width(self)
  end
  
  def theme
    self.class.theme
  end
  
  def mark_style
    self.class.mark_style
  end
  
  def nick_style
    self.class.nick_style
  end
  
  def mark_width
    self.class.mark_width
  end
  
  LEFT_MARGIN = 2
  MARK_RIGHT_MARGIN = 2
  
  def drawInteriorWithFrame_inView(frame, view)
    window = view.window
    if self.isHighlighted
      if window && window.isMainWindow && window.firstResponder == view
        color = theme.member_list_sel_color || NSColor.alternateSelectedControlTextColor
      else
        color = theme.member_list_sel_color || NSColor.selectedControlTextColor
      end
    elsif @member.op?
      color = theme.member_list_op_color
    else
      color = theme.member_list_color
    end
    
    attrs = {
      NSParagraphStyleAttributeName => mark_style,
      NSFontAttributeName => font,
      NSForegroundColorAttributeName => color,
    }
    
    rect = frame.dup
    rect.x += LEFT_MARGIN
    rect.width = mark_width
    
    mark = @member.mark
    unless mark.empty?
      mark.to_ns.drawInRect_withAttributes(rect, attrs)
    end
    
    attrs[NSParagraphStyleAttributeName] = nick_style
    
    offset = LEFT_MARGIN + mark_width + MARK_RIGHT_MARGIN
    rect = frame.dup
    rect.x += offset
    rect.width -= offset
    
    @member.nick.to_ns.drawInRect_withAttributes(rect, attrs)
  end
end
