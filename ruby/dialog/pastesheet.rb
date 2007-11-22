# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'cocoasheet'

class PasteSheet < CocoaSheet
  attr_accessor :uid, :cid
  ib_outlet :text, :sendButton, :notice_check
  first_responder :sendButton
  buttons :Send, :Cancel
  
  def startup(str, mode, notice)
    @notice_check.setState(notice ? 1 : 0)
    if mode == :edit
      @sheet.makeFirstResponder(@text)
    end
    @text.textStorage.setAttributedString(NSAttributedString.alloc.initWithString(str))
  end
  
  def shutdown(result)
    notice = @notice_check.state.to_i != 0
    if result == :send
      fire_event('onSend', @text.textStorage.string.to_s, notice)
    else
      fire_event('onCancel', notice)
    end
  end
end
