# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

class MainWindow < NSWindow
  def initialize
    @keyHandler = KeyEventHandler.alloc.init
  end
  
  def sendEvent(e)
    if e.oc_type == NSKeyDown
      return if @keyHandler.processKeyEvent(e) == 1
    end
    super_sendEvent(e)
  end
  
  def setKeyHandlerTarget(target)
    @keyHandler.target = target
  end
  
  def registerKeyHandler_key_modifiers(sel, key, mods)
    @keyHandler.registerSelector_key_modifiers(sel, key, mods)
  end
  
  def registerKeyHandler_character_modifiers(sel, char, mods)
    @keyHandler.registerSelector_character_modifiers(sel, char, mods)
  end
end
