# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'textfield'

class InputTextField < TextField
  
  def drawRect(rect)
    super_drawRect(rect)
    backgroundColor.set
    NSFrameRectWithWidth(bounds, 3)
  end
  
end
