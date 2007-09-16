# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'cocoasheet'

class PasteSheet < CocoaSheet
  attr_accessor :uid, :cid
  ib_outlet :sheet, :text, :sendButton
  first_responder :sendButton
  buttons "Send", "Cancel"
  
  def startup(str)
    @text.textStorage.setAttributedString(NSAttributedString.alloc.initWithString(str))
  end
  
  def shutdown(result)
    if result == :send
      fire_event('onSend', @text.textStorage.string.to_s)
    else
      fire_event('onCancel')
    end
  end
end
