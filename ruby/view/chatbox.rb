# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'utility'

class ChatBox < NSBox
  
  SPACE = 3
  
  def setFrame(rect)
    if subviews.count > 0
      f = rect
      box = log_base
      text = input_text
      boxframe = box.frame
      textframe = text.frame
    
      boxframe.x = 0.0
      boxframe.y = textframe.height + SPACE
      boxframe.width = f.width
      boxframe.height = f.height - textframe.height - SPACE
      box.setFrame(boxframe)
    
      textframe.x = 0.0
      textframe.y = 0.0
      textframe.width = f.width
      text.setFrame(textframe)
    end
    super_setFrame(rect)
  end
  
  def set_input_text_font(font)
    text = input_text
    text.setFont(font)
    
    # calculate height of the text field
    f = text.frame
    f.height = 1e+37
    f.height = text.cell.cellSizeForBounds(f).height.ceil + 4
    text.setFrameSize(f.size)
    
    # apply the current font to text
    e = text.currentEditor
    range = e.selectedRange if e
    s = text.stringValue
    text.setAttributedStringValue(NSAttributedString.alloc.init)
    text.setStringValue(s)
    e.setSelectedRange(range) if e
    
    setFrame(frame)
  end
  
  private
  
  def log_base
    content = subviews.objectAtIndex(0)
    content.subviews.objectAtIndex(0)
  end
  
  def input_text
    content = subviews.objectAtIndex(0)
    content.subviews.objectAtIndex(1)
  end
end
