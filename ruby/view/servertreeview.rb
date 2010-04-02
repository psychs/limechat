# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'treeview'

class AServerTreeView < TreeView
  attr_accessor :responderDelegate
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
    if @responderDelegate
      @responderDelegate.serverTreeViewAcceptsFirstResponder
      false
    else
      true
    end
  end
  
  def themeChanged
    @bgcolor = @theme.treeBackgroundColor
    @top_line_color = @theme.treeSelTopLineColor
    @bottom_line_color = @theme.treeSelBottomLineColor
    from = @theme.treeSelTopColor
    to = @theme.treeSelBottomColor
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
