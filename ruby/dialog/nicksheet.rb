# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the same terms as Ruby.

class NickSheet < OSX::NSObject
  include OSX
  include DialogHelper
  attr_accessor :window, :delegate, :uid
  attr_reader :modal
  ib_outlet :sheet, :currentNickText, :newNickText
  
  def initialize
    @prefix = 'nickSheet'
  end
  
  def loadNib
    NSBundle.loadNibNamed_owner('NickSheet', self)
  end
  
  def start(currentNick)
    @modal = true
    @sheet.makeFirstResponder(@newNickText)
    @currentNickText.setStringValue(currentNick)
    @newNickText.setStringValue(currentNick)
    NSApp.beginSheet_modalForWindow_modalDelegate_didEndSelector_contextInfo(@sheet, @window, self, 'sheetDidEnd:returnCode:contextInfo:', nil)
  end
  
  addRubyMethod_withType 'sheetDidEnd:returnCode:contextInfo:', 'v@:@i^v'
  def sheetDidEnd_returnCode_contextInfo(sender, code, info)
    @sheet.orderOut(self)
    @modal = false
    if code != 0
      fire_event('onOk', @newNickText.stringValue.to_s)
    else
      fire_event('onCancel')
    end
  end
  
  def onOk(sender)
    NSApp.endSheet_returnCode(@sheet, 1)
  end
  
  def onCancel(sender)
    NSApp.endSheet_returnCode(@sheet, 0)
  end
end
