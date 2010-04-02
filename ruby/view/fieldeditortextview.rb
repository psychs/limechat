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
  
  def register_keyHandler(*args, &handler)
    @keyHandler.register_keyHandler(*args, &handler)
  end
  
  def keyDown(e)
    return if @keyHandler.process_key_event(e)
    super_keyDown(e)
  end
end
