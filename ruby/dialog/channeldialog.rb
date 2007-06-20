# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'dialoghelper'

class ChannelDialog < OSX::NSObject
  include OSX
  include DialogHelper
  
  attr_accessor :window
  attr_accessor :delegate, :prefix
  attr_reader :uid, :cid
  ib_mapped_outlet :nameText, :passwordText, :modeText, :topicText, :auto_joinCheck, :keywordCheck, :unreadCheck, :consoleCheck
  ib_outlet :okButton
  
  def initialize
    @prefix = 'channelDialog'
  end
  
  def config
    @c
  end
  
  def start(config, uid, cid)
    @c = config.dup
    @uid = uid
    @cid = cid
    NSBundle.loadNibNamed_owner('ChannelDialog', self)
    if cid < 0
      @window.setTitle("New Channel")
    else
      @nameText.setEditable(false)
      @nameText.setSelectable(false)
      @nameText.setBezeled(false)
      @nameText.setDrawsBackground(false)
      #@nameText.setEnabled(false)
    end
    load
    update
    show
  end
  
  def show
    @window.makeKeyAndOrderFront(self)
  end
  
  def close
    @delegate = nil
    @window.close
  end
  
  def windowWillClose(sender)
    fire_event('onClose')
  end
  
  def onOk(sender)
    save
    fire_event('onOk', @c)
    @window.close
  end
  
  def onCancel(sender)
    @window.close
  end
  
  def load
    load_mapped_outlets(@c)
  end
  
  def save
    save_mapped_outlets(@c)
  end
  
  def controlTextDidChange(n)
    update
  end
  
  def update
    s = @nameText.stringValue.to_s
    @okButton.setEnabled(s.channelname?)
  end
end
