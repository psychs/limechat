# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'listview'
require 'user'

class MemberListView < ListView
  attr_accessor :key_delegate, :drop_delegate
  attr_writer :theme
  
  def initialize
    @bgcolor = NSColor.controlBackgroundColor
  end
  
  def awakeFromNib
    registerForDraggedTypes([NSFilenamesPboardType])
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
      if window && window.isMainWindow && window.firstResponder == self
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
  
  
  def draggingEntered(info)
    draggingUpdated(info)
  end
  
  def draggingUpdated(info)
    if !dragged_files(info).empty? && dragged_row(info) >= 0
      draw_dragging_position(info, true)
      NSDragOperationCopy
    else
      draw_dragging_position(info, false)
      NSDragOperationNone
    end
  end
  
  def draggingEnded(info)
    draw_dragging_position(info, false)
  end
  
  def draggingExited(info)
    draw_dragging_position(info, false)
  end
  
  def prepareForDragOperation(info)
    !dragged_files(info).empty? && dragged_row(info) >= 0
  end
  
  def performDragOperation(info)
    files = dragged_files(info)
    if !files.empty?
      row = dragged_row(info)
      if row >= 0
        # received files
        @drop_delegate.memberListView_dropFiles(files, row)
        true
      else
        false
      end
    else
      false
    end
  end
  
  def concludeDragOperation(info)
  end
  
  private
  
  def dragged_row(info)
    pt = convertPoint_fromView(info.draggingLocation, nil)
    rowAtPoint(pt)
  end
  
  def draw_dragging_position(info, on)
    if on
      row = dragged_row(info)
      if row < 0
        deselectAll(nil)
      else
        select(row)
      end
    else
      deselectAll(nil)
    end
  end
  
  def dragged_files(info)
    files = info.draggingPasteboard.propertyListForType(NSFilenamesPboardType).to_ruby
    files.select{|i| File.file?(i) }
  rescue
    []
  end
  
end


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
  
  def theme_changed
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
