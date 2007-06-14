# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the same terms as Ruby.

class TreeView < OSX::NSOutlineView
  include OSX
  attr_accessor :responder_delegate
  
  def acceptsFirstResponder
    @responder_delegate.tree_acceptFirstResponder if @responder_delegate
    false
  end
  
  def select(index, scroll=true)
    self.selectRowIndexes_byExtendingSelection(NSIndexSet.indexSetWithIndex(index), false)
    self.scrollRowToVisible(index) if scroll
  end
  
  def menuForEvent(event)
    p = convertPoint_fromView(event.locationInWindow, nil)
    i = rowAtPoint(p)
    if i >= 0
      select(i)
    end
    self.menu
  end
  
  def _highlightColorForCell(cell)
    nil
  end
  
  def _highlightRow_clipRect(row, rect)
    return unless NSApp.isActive
    unless @gradient
      begin_color = NSColor.colorWithCalibratedRed_green_blue_alpha(173.0/255.0, 187.0/255.0, 208.0/255.0, 1.0)
      end_color = NSColor.colorWithCalibratedRed_green_blue_alpha(152.0/255.0, 170.0/255.0, 196.0/255.0, 1.0)
      @gradient = GradientFill.gradientWithBeginColor_endColor(begin_color, end_color)
    end
    rect = self.rectOfRow(row)
    @gradient.fillRect(rect)
    
    unless @bottom_line_color
      @bottom_line_color = NSColor.colorWithCalibratedRed_green_blue_alpha(140.0/255.0, 152.0/255.0, 176.0/255.0, 1.0)
    end
    @bottom_line_color.set
    bottom_line_rect = NSMakeRect(NSMinX(rect), NSMaxY(rect) - 1.0, NSWidth(rect), 1.0)
    NSRectFill(bottom_line_rect)
  end
  
  def drawBackgroundInClipRect(rect)
    unless @bgcolor
      @bgcolor = NSColor.colorWithCalibratedRed_green_blue_alpha(229.0/255.0, 237.0/255.0, 247.0/255.0, 1.0)
    end
    @bgcolor.set
    NSRectFill(rect)
  end
end
