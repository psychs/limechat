# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

class DialogWindow < OSX::NSWindow
  include OSX
  attr_accessor :key_delegate
  
  def sendEvent(e)
    if @key_delegate
      if e.oc_type == NSKeyDown
        k = e.keyCode
        m = e.modifierFlags
        shift = m & NSShiftKeyMask > 0
        ctrl = m & NSControlKeyMask > 0
        alt = m & NSAlternateKeyMask > 0
        cmd = m & NSCommandKeyMask > 0
        
        if !shift && !ctrl && !alt && !cmd
          # none
          case k
          when 53 # esc
            if @key_delegate.respond_to?(:dialogWindow_onEscape)
              @key_delegate.dialogWindow_onEscape
              return
            end
          end
        elsif !shift && ctrl && !alt && !cmd || !shift && !ctrl && !alt && cmd
          # cmd or ctrl
          case k
          when 125 #down
            if @key_delegate.respond_to?(:dialogWindow_onDown)
              @key_delegate.dialogWindow_onDown
              return
            end
          when 126 #up
            if @key_delegate.respond_to?(:dialogWindow_onUp)
              @key_delegate.dialogWindow_onUp
              return
            end
          end
        end
      end
    end
    super_sendEvent(e)
  end
end
