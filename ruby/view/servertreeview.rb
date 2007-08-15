# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'treeview'

class ServerTreeView < TreeView
  include OSX
  attr_accessor :responder_delegate
  
  #objc_method :acceptsFirstResponder, 'c@:'
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
