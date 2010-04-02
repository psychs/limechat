# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

class DialogWindow < NSWindow
  attr_accessor :keyDelegate
  
  def sendEvent(e)
    if @keyDelegate
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
            if @keyDelegate.respond_to?(:dialogWindow_escape)
              @keyDelegate.dialogWindow_escape
              return
            end
          when 76 #enter
            if @keyDelegate.respond_to?(:dialogWindow_enter)
              @keyDelegate.dialogWindow_enter
              return
            end
          end
        elsif !shift && ctrl && !alt && !cmd || !shift && !ctrl && !alt && cmd
          # cmd or ctrl
          case k
          when 125 #down
            if @keyDelegate.respond_to?(:dialogWindow_moveDown)
              @keyDelegate.dialogWindow_moveDown
              return
            end
          when 126 #up
            if @keyDelegate.respond_to?(:dialogWindow_moveUp)
              @keyDelegate.dialogWindow_moveUp
              return
            end
          end
        end
      end
    end
    super_sendEvent(e)
  end
end
