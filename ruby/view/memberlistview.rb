# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'listview'

class MemberListView < ListView
  attr_accessor :key_delegate
  
  def keyDown(e)
    if @key_delegate
      case e.keyCode
      when 123..126 # cursor keys
      when 116,121  # page up/down
      else
        @key_delegate.memberListView_keyDown(e)
        return
      end
    end
    super_keyDown(e)
  end
end


class MemberListViewCell < NSCell
  attr_writer :member
  
  def setup(window, theme)
    @window = window
    @theme = theme
    @mark_width = 0
    @style = NSMutableParagraphStyle.alloc.init
    @style.setAlignment(NSLeftTextAlignment)
    @style.setLineBreakMode(NSLineBreakByTruncatingTail)
  end
  
  def font_changed
    calculate_mark_width
  end
  
  def calculate_mark_width
    @mark_width = 0
    ['@', '+'].each do |s|
      n = s.to_ns.sizeWithAttributes(NSFontAttributeName => font)
      @mark_width = n.width if n.width > @mark_width
    end
  end
  
  LEFT_MARGIN = 2
  MARK_RIGHT_MARGIN = 2
  
  def drawInteriorWithFrame_inView(frame, view)
    if self.isHighlighted
      if NSApp.isActive && @window.firstResponder == view
        color = NSColor.whiteColor
      else
        color = NSColor.blackColor
      end
    elsif @member.o
      color = @theme.member_list_op_color
    else
      color = @theme.member_list_color
    end
    
    attrs = {
      NSParagraphStyleAttributeName => @style,
      NSFontAttributeName => font,
      NSForegroundColorAttributeName => color,
    }
    
    rect = frame.dup
    rect.x += LEFT_MARGIN
    rect.width -= LEFT_MARGIN
    
    mark = @member.mark
    unless mark.empty?
      mark.to_ns.drawInRect_withAttributes(rect, attrs)
    end
    
    rect.x += @mark_width + MARK_RIGHT_MARGIN
    rect.width -= @mark_width + MARK_RIGHT_MARGIN
    
    @member.nick.to_ns.drawInRect_withAttributes(rect, attrs)
  end
end
