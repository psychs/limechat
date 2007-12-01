# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'dialoghelper'

class ChannelDialog < OSX::NSObject
  include OSX
  include DialogHelper
  
  attr_accessor :delegate, :prefix, :parent
  attr_reader :uid, :cid, :modal
  ib_outlet :window
  ib_mapped_outlet :nameText, :passwordText, :modeText, :topicText, :auto_joinCheck, :keywordCheck, :unreadCheck, :consoleCheck
  ib_outlet :okButton
  
  def initialize
    @prefix = 'channelDialog'
  end
  
  def config
    @c
  end
  
  def loadNib
    NSBundle.loadNibNamed_owner('ChannelDialog', self)
  end
  
  def start(config, uid, cid)
    @c = config.dup
    @uid = uid
    @cid = cid
    loadNib
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
  
  def start_sheet(owner, config, add=false)
    @modal = true
    @c = config.dup
    loadNib
    if add
      @c.name = ''
    else
      @nameText.setEditable(false)
      @nameText.setSelectable(false)
      @nameText.setBezeled(false)
      @nameText.setDrawsBackground(false)
    end
    load
    update
    NSApp.beginSheet_modalForWindow_modalDelegate_didEndSelector_contextInfo(@window, owner, self, 'sheetDidEnd:returnCode:contextInfo:', nil)
  end
  
  def sheetDidEnd_returnCode_contextInfo(sender, code, info)
    @window.close
    @modal = false
    if code != 0
      save
      fire_event('onOk', @c)
    else
      fire_event('onCancel')
    end
  end
  
  def show
    @window.centerOfWindow(@parent) unless @window.isVisible
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
    if @modal
      NSApp.endSheet_returnCode(@window, 1)
    else
      save
      fire_event('onOk', @c)
      @window.close
    end
  end
  
  def onCancel(sender)
    if @modal
      NSApp.endSheet_returnCode(@window, 0)
    else
      @window.close
    end
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
