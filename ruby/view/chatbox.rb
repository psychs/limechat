# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'utility'

class ChatBox < NSBox
  
  SPACE = 3
  
  def setFrame(rect)
    f = rect
    content = subviews.objectAtIndex(0)
    box = content.subviews.objectAtIndex(0)
    text = content.subviews.objectAtIndex(1)
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
    
    super_setFrame(rect)
  end
end
