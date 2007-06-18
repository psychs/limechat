# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

class LogView < OSX::WebView
  include OSX
  attr_accessor :key_delegate, :resize_delegate
  
  def keyDown(e)
    @key_delegate.logView_keyDown(e) if @key_delegate
  end
  
  def setFrame(rect)
    @resize_delegate.logView_willResize(rect) if @resize_delegate
    super_setFrame(rect)
    @resize_delegate.logView_didResize(rect) if @resize_delegate
  end
end
