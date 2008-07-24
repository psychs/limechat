# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

class TextField < NSTextField
  
  def focus
    window.makeFirstResponder(self)
    e = currentEditor
    e.setSelectedRange(NSRange.new(stringValue.length, 0))
    e.scrollRangeToVisible(e.selectedRange)
  end
  
  def drawRect(rect)
    super_drawRect(rect)
    
    backgroundColor.set
    path = NSBezierPath.bezierPath
    rect = bounds
    rect.height = 3
    path.appendBezierPathWithRect(rect)
    rect = bounds
    rect.width = 2
    path.appendBezierPathWithRect(rect)
    rect = bounds
    rect.x = rect.x + rect.width - 2
    rect.width = 2
    path.appendBezierPathWithRect(rect)
    rect = bounds
    rect.y = rect.y + rect.height - 2
    rect.height = 2
    path.appendBezierPathWithRect(rect)
    path.fill
  end
  
end
