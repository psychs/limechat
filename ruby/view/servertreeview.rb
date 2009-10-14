# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'treeview'

class ServerTreeView < TreeView
  attr_accessor :responder_delegate
  attr_writer :theme
  
  def initialize
    @bgcolor = NSColor.from_rgb(229, 237, 247)
    @top_line_color = NSColor.from_rgb(173, 187, 208)
    @bottom_line_color = NSColor.from_rgb(140, 152, 176)
    from = NSColor.from_rgb(173, 187, 208)
    to = NSColor.from_rgb(152, 170, 196)
    @gradient = NSGradient.alloc.initWithStartingColor_endingColor(from, to)
  end
  
  def acceptsFirstResponder
    if @responder_delegate
      @responder_delegate.serverTreeView_acceptFirstResponder
      false
    else
      true
    end
  end
  
  def theme_changed
    @bgcolor = @theme.tree_bgcolor
    @top_line_color = @theme.tree_sel_top_line_color
    @bottom_line_color = @theme.tree_sel_bottom_line_color
    from = @theme.tree_sel_top_color
    to = @theme.tree_sel_bottom_color
    @gradient = NSGradient.alloc.initWithStartingColor_endingColor(from, to)
  end
  
  def _highlightColorForCell(cell)
    nil
  end
  
  def _highlightRow_clipRect(row, rect)
    return unless NSApp.isActive
    frame = self.rectOfRow(row)
    rect = frame.dup
    rect.y += 1
    rect.height -= 2
    @gradient.drawInRect_angle(rect, 90)
    
    @top_line_color.set
    rect = frame.dup
    rect.height = 1
    NSRectFill(rect)
    
    @bottom_line_color.set
    rect = frame.dup
    rect.y = rect.y + rect.height - 1
    rect.height = 1
    NSRectFill(rect)
  end
  
  def drawBackgroundInClipRect(rect)
    @bgcolor.set
    NSRectFill(rect)
  end
end
