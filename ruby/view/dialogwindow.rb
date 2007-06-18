# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

class DialogWindow < OSX::NSWindow
  include OSX
  attr_accessor :key_delegate
  
  def sendEvent(e)
    if @key_delegate
      if e.oc_type == NSKeyDown
        k = e.keyCode
        case k
        when 53 # esc
          @key_delegate.dialogWindow_onEscape
        end
      end
    end
    super_sendEvent(e)
  end
end
