# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the same terms as Ruby.

class TableProgressIndicator < OSX::NSProgressIndicator
  include OSX
  
  def mouseDown(e)
    self.superview.mouseDown(e)
  end
  
  def rightMouseDown(e)
    self.superview.rightMouseDown(e)
  end
end
