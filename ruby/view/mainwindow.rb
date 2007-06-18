# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

class MainWindow < OSX::NSWindow
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
        
        #puts k
        
        if !shift && !ctrl && !alt && !cmd
          # none
          case k
          when 48 #tab
            @key_delegate.controlTab
            return
          when 115 #home
            return if @key_delegate.scroll(:home)
          when 116 #pageup
            return if @key_delegate.scroll(:up)
          when 121 #pagedown
            return if @key_delegate.scroll(:down)
          when 119 #end
            return if @key_delegate.scroll(:end)
          end
        elsif shift && !ctrl && !alt && !cmd
          # shift
          case k
          when 48 #tab
            @key_delegate.controlShiftTab
            return
          end
        elsif !shift && ctrl && !alt && !cmd
          # ctrl
          case k
          when 48 #tab
            @key_delegate.controlTab
            return
          when 123 #left
            @key_delegate.controlLeft
            return
          when 124 #right
            @key_delegate.controlRight
            return
          when 125 #down
            @key_delegate.controlDown
            return
          when 126 #up
            @key_delegate.controlUp
            return
          end
        elsif shift && ctrl && !alt && !cmd
          # ctrl-shift
          case k
          when 48 #tab
            @key_delegate.controlShiftTab
            return
          end
        elsif !shift && !ctrl && !alt && cmd
          # cmd
          case k
          when 18..23,25..29,82..89,91,92
            @key_delegate.number(keynum(k))
            return
          when 123 #left
            @key_delegate.commandLeft
            return
          when 124 #right
            @key_delegate.commandRight
            return
          when 125 #down
            @key_delegate.commandDown
            return
          when 126 #up
            @key_delegate.commandUp
            return
          end
        end
      end
    end
    super_sendEvent(e)
  end
  
  def keynum(keycode)
    case keycode
    when 29,82; 0
    when 18,83; 1
    when 19,84; 2
    when 20,85; 3
    when 21,86; 4
    when 23,87; 5
    when 22,88; 6
    when 26,89; 7
    when 28,91; 8
    when 25,92; 9
    else nil
    end
  end
end
