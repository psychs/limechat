# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'dialoghelper'

class PasteSheet < OSX::NSObject
  include OSX
  include DialogHelper
  attr_accessor :window, :delegate, :prefix, :uid, :cid
  attr_reader :modal
  ib_outlet :sheet, :text, :sendButton
  
  def initialize
    @prefix = 'pasteSheet'
  end
  
  def start(str)
    NSBundle.loadNibNamed_owner('PasteSheet', self)
    @modal = true
    @sheet.makeFirstResponder(@sendButton)
    @text.textStorage.setAttributedString(NSAttributedString.alloc.initWithString(str))
    NSApp.beginSheet_modalForWindow_modalDelegate_didEndSelector_contextInfo(@sheet, @window, self, 'sheetDidEnd:returnCode:contextInfo:', nil)
  end
  
  addRubyMethod_withType 'sheetDidEnd:returnCode:contextInfo:', 'v@:@i^v'
  def sheetDidEnd_returnCode_contextInfo(sender, code, info)
    @sheet.orderOut(self)
    @modal = false
    if code != 0
      fire_event('onSend', @text.textStorage.string.to_s)
    else
      fire_event('onCancel')
    end
  end
  
  def onSend(sender)
    NSApp.endSheet_returnCode(@sheet, 1)
  end
  
  def onCancel(sender)
    NSApp.endSheet_returnCode(@sheet, 0)
  end
end
