# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

class TextField < OSX::NSTextField
  include OSX
  
  def focus
    window.makeFirstResponder(self)
    e = currentEditor
    e.setSelectedRange(NSRange.new(stringValue.size, 0))
    e.scrollRangeToVisible(e.selectedRange)
  end
end
