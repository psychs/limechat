# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

class FieldEditorTextView < OSX::NSTextView
  include OSX
  attr_accessor :paste_delegate

  def paste(sender)
    if @paste_delegate && @paste_delegate.respond_to?(:fieldEditorTextView_paste)
      return if @paste_delegate.fieldEditorTextView_paste(self)
    end
    super_paste(sender)
  end
end
