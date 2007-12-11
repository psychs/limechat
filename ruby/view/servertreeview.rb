# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'treeview'

class ServerTreeView < TreeView
  attr_accessor :responder_delegate
  attr_writer :theme
  
  def initialize
    @bgcolor = NSColor.from_rgb(229, 237, 247)
    from = NSColor.from_rgb(173, 187, 208)
    to = NSColor.from_rgb(152, 170, 196)
    @gradient = GradientFill.gradientWithBeginColor_endColor(from, to)
    @bottom_line_color = NSColor.from_rgb(140, 152, 176)
  end
  
  def acceptsFirstResponder
    if @responder_delegate
      @responder_delegate.serverTreeView_acceptFirstResponder
      false
    else
      true
    end
  end
  
  def _highlightColorForCell(cell)
    nil
  end
  
  def _highlightRow_clipRect(row, rect)
    return unless NSApp.isActive
    rect = self.rectOfRow(row)
    @gradient.fillRect(rect)
    @bottom_line_color.set
    bottom_line_rect = NSMakeRect(NSMinX(rect), NSMaxY(rect) - 1.0, NSWidth(rect), 1.0)
    NSRectFill(bottom_line_rect)
  end
  
  def drawBackgroundInClipRect(rect)
    @bgcolor.set
    NSRectFill(rect)
  end
end
