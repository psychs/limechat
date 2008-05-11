# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'cocoasheet'

class NickSheet < CocoaSheet
  attr_accessor :uid
  ib_outlet :currentNickText, :newNickText
  first_responder :newNickText
  buttons :Ok, :Cancel
  
  def startup(currentNick)
    @currentNickText.setStringValue(currentNick)
    @newNickText.setStringValue(currentNick)
  end
  
  def shutdown(result)
    if result == :ok
      fire_event('onOk', @newNickText.stringValue.to_s)
    else
      fire_event('onCancel')
    end
  end
end
