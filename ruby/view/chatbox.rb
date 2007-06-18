# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

class ChatBox < OSX::NSBox
  include OSX
  
  def setFrame(rect)
    space = 3
    
    f = rect
    content = subviews.objectAtIndex(0)
    box = content.subviews.objectAtIndex(0)
    text = content.subviews.objectAtIndex(1)
    boxframe = box.frame
    textframe = text.frame
    
    boxframe.origin.x = 0.0
    boxframe.origin.y = textframe.size.height + space
    boxframe.size.width = f.size.width
    boxframe.size.height = f.size.height - textframe.size.height - space
    box.setFrame(boxframe)
    
    textframe.origin.x = 0.0
    textframe.origin.y = 0.0
    textframe.size.width = f.size.width
    text.setFrame(textframe)
    
    super_setFrame(rect)
  end
end
