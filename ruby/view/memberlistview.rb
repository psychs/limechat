# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'listview'
require 'user'

class MemberListView < ListView
  attr_accessor :key_delegate
  attr_writer :theme
  
  def initialize
    @bgcolor = NSColor.controlBackgroundColor
  end
  
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
  
  def theme_changed
    @bgcolor = @theme.member_list_bgcolor
    @top_line_color = @theme.member_list_sel_top_line_color
    @bottom_line_color = @theme.member_list_sel_bottom_line_color
    from = @theme.member_list_sel_top_color
    to = @theme.member_list_sel_bottom_color
    if from && to
      @gradient = GradientFill.gradientWithBeginColor_endColor(from, to)
    else
      @gradient = nil
    end
  end
  
  def _highlightColorForCell(cell)
    nil
  end
  
  def _highlightRow_clipRect(row, rect)
    frame = self.rectOfRow(row)
    if @top_line_color && @bottom_line_color && @gradient
      rect = frame.dup
      rect.y += 1
      rect.height -= 2
      @gradient.fillRect(rect)

      @top_line_color.set
      rect = frame.dup
      rect.height = 1
      NSRectFill(rect)

      @bottom_line_color.set
      rect = frame.dup
      rect.y = rect.y + rect.height - 1
      rect.height = 1
      NSRectFill(rect)
    else
      if NSApp.isActive && window.firstResponder == self
        NSColor.alternateSelectedControlColor.set
      else
        NSColor.selectedControlColor.set
      end
      NSRectFill(frame)
    end
  end
  
  def drawBackgroundInClipRect(rect)
    @bgcolor.set
    NSRectFill(rect)
  end
end


class MemberListViewCell < NSCell
  attr_writer :member, :singleton
  
  def initialize
    @mark_width = 0
  end
  
  def copyWithZone(zone)
    obj = super_copyWithZone(zone)
    obj.singleton = @singleton || self
    obj
  end
  
  def setup(window, theme)
    @window = window
    @theme = theme
    @mark_style = NSMutableParagraphStyle.alloc.init
    @mark_style.setAlignment(NSCenterTextAlignment)
    @nick_style = NSMutableParagraphStyle.alloc.init
    @nick_style.setAlignment(NSLeftTextAlignment)
    @nick_style.setLineBreakMode(NSLineBreakByTruncatingTail)
  end
  
  def theme_changed
    calculate_mark_width
  end
  
  def calculate_mark_width
    @mark_width = 0
    User.marks.each do |s|
      n = s.to_ns.sizeWithAttributes(NSFontAttributeName => font)
      @mark_width = n.width if n.width > @mark_width
    end
  end
  
  LEFT_MARGIN = 2
  MARK_RIGHT_MARGIN = 2
  
  def drawInteriorWithFrame_inView(frame, view)
    return @singleton.drawInteriorWithFrame_inView(frame, view) if @singleton
    return unless @member && @theme
    if self.isHighlighted
      if NSApp.isActive && @window && @window.firstResponder == view
        color = @theme.member_list_sel_color || NSColor.alternateSelectedControlTextColor
      else
        color = @theme.member_list_sel_color || NSColor.selectedControlTextColor
      end
    elsif @member.o
      color = @theme.member_list_op_color
    else
      color = @theme.member_list_color
    end
    
    attrs = {
      NSParagraphStyleAttributeName => @mark_style,
      NSFontAttributeName => font,
      NSForegroundColorAttributeName => color,
    }
    
    rect = frame.dup
    rect.x += LEFT_MARGIN
    rect.width = @mark_width
    
    mark = @member.mark
    unless mark.empty?
      mark.to_ns.drawInRect_withAttributes(rect, attrs)
    end
    
    attrs[NSParagraphStyleAttributeName] = @nick_style
    
    offset = LEFT_MARGIN + @mark_width + MARK_RIGHT_MARGIN
    rect = frame.dup
    rect.x += offset
    rect.width -= offset
    
    @member.nick.to_ns.drawInRect_withAttributes(rect, attrs)
  end
end
