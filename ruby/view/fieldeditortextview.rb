# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

class FieldEditorTextView < NSTextView
  attr_accessor :pasteDelegate
  
  def initialize
    @keyHandler = KeyEventHandler.new
  end

  def paste(sender)
    if @pasteDelegate
      return if @pasteDelegate.fieldEditorTextView_paste(self)
    end
    super_paste(sender)
  end
  
  def setKeyHandlerTarget(target)
    @keyHandler.target = target
  end
  
  def registerKeyHandler_key_modifiers(sel, key, mods)
    @keyHandler.registerSelector_key_modifiers(sel, key, mods)
  end
  
  def keyDown(e)
    return if @keyHandler.processKeyEvent(e) == 1
    super_keyDown(e)
  end
end
