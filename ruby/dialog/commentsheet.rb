# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'cocoasheet'

class CommentSheet < CocoaSheet
  attr_accessor :uid, :cid
  ib_outlet :label, :text
  first_responder :text
  buttons :Ok, :Cancel
  
  def startup(prompt, str='')
    @label.setStringValue(prompt)
    @text.setStringValue(str)
  end
  
  def shutdown(result)
    if result == :ok
      fire_event('onOk', @text.stringValue.to_s)
    else
      fire_event('onCancel')
    end
  end
end
