# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

class MainWindow < OSX::NSWindow
  include OSX
  attr_accessor :key_delegate
  
  def copy(sender)
  end
  
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
          when 48 #tab
            return if @key_delegate.tab
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
            return if @key_delegate.shiftTab
          end
        elsif !shift && ctrl && !alt && !cmd
          # ctrl
          case k
          when 36 #enter
            return if @key_delegate.controlEnter
          when 48 #tab
            return if @key_delegate.controlTab
          when 123 #left
            return if @key_delegate.controlLeft
          when 124 #right
            return if @key_delegate.controlRight
          when 125 #down
            return if @key_delegate.controlDown
          when 126 #up
            return if @key_delegate.controlUp
          end
        elsif shift && ctrl && !alt && !cmd
          # ctrl-shift
          case k
          when 48 #tab
            return if @key_delegate.controlShiftTab
          end
        elsif !shift && !ctrl && alt && !cmd
          # alt
          case k
          when 49 #space
            return if @key_delegate.altSpace
          end
        elsif shift && !ctrl && alt && !cmd
          # alt-shift
          case k
          when 49 #space
            return if @key_delegate.altShiftSpace
          end
        elsif !shift && !ctrl && !alt && cmd
          # cmd
          case k
          when 18..23,25,26,28,29,82..89,91,92
            return if @key_delegate.number(keynum(k))
          when 125 #down
            return if @key_delegate.commandDown
          when 126 #up
            return if @key_delegate.commandUp
          end
        elsif !shift && !ctrl && alt && cmd
          # cmd-alt
          case k
          when 123 #left
            return if @key_delegate.commandAltLeft
          when 124 #right
            return if @key_delegate.commandAltRight
          when 125 #down
            return if @key_delegate.commandDown
          when 126 #up
            return if @key_delegate.commandUp
          end
        end
      end
    end
    super_sendEvent(e)
  end
  
  private
  
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
