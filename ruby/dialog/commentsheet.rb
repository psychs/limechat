# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the same terms as Ruby.

class CommentSheet < OSX::NSObject
  include OSX
  include DialogHelper
  attr_accessor :window, :delegate, :prefix
  attr_reader :modal
  ib_outlet :sheet, :label, :text
  attr_accessor :uid, :cid
  
  def initialize
    @prefix = 'commentSheet'
  end
  
  def loadNib
    NSBundle.loadNibNamed_owner('CommentSheet', self)
  end
  
  def start(prompt, str='')
    @modal = true
    @sheet.makeFirstResponder(@text)
    @label.setStringValue(prompt)
    @text.setStringValue(str)
    NSApp.beginSheet_modalForWindow_modalDelegate_didEndSelector_contextInfo(@sheet, @window, self, 'sheetDidEnd:returnCode:contextInfo:', nil)
  end
  
  addRubyMethod_withType 'sheetDidEnd:returnCode:contextInfo:', 'v@:@i^v'
  def sheetDidEnd_returnCode_contextInfo(sender, code, info)
    @sheet.orderOut(self)
    @modal = false
    if code != 0
      fire_event('onOk', @text.stringValue.to_s)
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

#NSBeginAlertSheet('Title', 'OK', 'Cancel', nil, @window, self, 'commentSheetDidEnd:returnCode:contextInfo:', nil, nil, 'Please input comment.')
