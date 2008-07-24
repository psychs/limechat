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
    NSFrameRectWithWidth(bounds, 3)
  end
  
end
