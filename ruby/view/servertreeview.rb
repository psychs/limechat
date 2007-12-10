# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'treeview'

class ServerTreeView < TreeView
  attr_accessor :responder_delegate
  
  def initialize
    #@active_bgcolor = NSColor.from_rgb(0xd6, 0xdd, 0xe5)
    @active_bgcolor = NSColor.from_rgb(0xe5, 0xed, 0xf7)
    @inactive_bgcolor = NSColor.from_rgb(0xe8, 0xe8, 0xe8)

    @active_top_line_color = NSColor.from_rgb(0x95, 0x99, 0xb0)
    from = NSColor.from_rgb(0xab, 0xb8, 0xc5)
    to = NSColor.from_rgb(0x7e, 0x8e, 0x9f)
    @active_gradient = GradientFill.gradientWithBeginColor_endColor(from, to)
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

    line_rect = rect.dup
    line_rect.height = 1
    @active_top_line_color.set
    NSRectFill(line_rect)
    
    rect.y += 1
    rect.height -= 1
    @active_gradient.fillRect(rect)
  end
  
  def drawBackgroundInClipRect(rect)
    if NSApp.isActive
      @active_bgcolor.set
    else
      @inactive_bgcolor.set
    end
    NSRectFill(rect)
  end
end
