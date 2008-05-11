# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

class FieldEditorTextView < NSTextView
  attr_accessor :paste_delegate
  
  def initialize
    @key_handler = KeyEventHandler.new
  end

  def paste(sender)
    if @paste_delegate
      return if @paste_delegate.fieldEditorTextView_paste(self)
    end
    super_paste(sender)
  end
  
  def register_key_handler(*args, &handler)
    @key_handler.register_key_handler(*args, &handler)
  end
  
  def keyDown(e)
    return if @key_handler.process_key_event(e)
    super_keyDown(e)
  end
end
