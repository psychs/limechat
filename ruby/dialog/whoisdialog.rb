# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'dialoghelper'

class WhoisDialog < NSObject
  include DialogHelper
  attr_accessor :delegate, :prefix
  attr_reader :nick
  ib_outlet :window, :nickText, :loginText, :realnameText, :addressText
  ib_outlet :serverText, :serverinfoText, :channelsCombo, :awayText, :idleText, :signonText
  ib_outlet :joinButton, :closeButton
  
  def initialize
    @prefix = 'whoisDialog'
    @operator = false
  end
  
  def start(nick, username, address, realname)
    NSBundle.loadNibNamed_owner('WhoisDialog', self)
    set_basic_info(nick, username, address, realname)
    @window.makeFirstResponder(@closeButton)
    show
  end
  
  def nick=(value)
    @nick = value.dup
    @window.setTitle("#{@nick}")
    update_nick
  end
  
  def update_nick
    @nickText.setStringValue(@operator ? "#{@nick} (IRC Operator)" : @nick)
  end
  
  def set_basic_info(tonick, username, address, realname)
    self.nick = tonick
    @loginText.setStringValue(username)
    @addressText.setStringValue(address)
    @realnameText.setStringValue(realname)
    set_away_message('')
    @channelsCombo.removeAllItems
    update
  end
  
  def set_channels(channels)
    @channelsCombo.addItemsWithTitles(channels)
    update
  end
  
  def set_server(server, serverinfo)
    @serverText.setStringValue(server)
    @serverinfoText.setStringValue(serverinfo)
  end
  
  def set_time(idle, signon)
    @idleText.setStringValue(idle)
    @signonText.setStringValue(signon)
  end
  
  def set_away_message(text)
    @awayText.setStringValue(text)
  end
  
  def set_operator
    @operator = true
    update_nick
  end
  
  ROTATE_COUNT = 10
  OFFSET_SIZE = NSSize.new(20, -20)
  @@place = 0
  
  def show
    unless @window.isVisible
      scr = NSScreen.screens[0]
      if scr
        p = scr.visibleFrame.center
        p -= @window.frame.size / 2
        p += OFFSET_SIZE * (@@place - ROTATE_COUNT/2)
        @window.setFrameOrigin(p)
        @@place += 1
        @@place = 0 if @@place >= ROTATE_COUNT
      end
    end
    @window.makeKeyAndOrderFront(self)
  end
  
  def close
    @delegate = nil
    @window.close
  end
  
  def windowWillClose(sender)
    fire_event('onClose')
  end
  
  def onClose(sender)
    @window.close
  end
  
  def onTalk(sender)
    fire_event('onTalk', @nick)
  end
  
  def onUpdate(sender)
    fire_event('onUpdate', @nick)
  end
  
  def onJoin(sender)
    sel = @channelsCombo.selectedItem
    return unless sel
    ch = sel.title.to_s
    ch = $~.post_match if /^[+@]/ =~ ch
    fire_event('onJoin', ch)
  end
  
  def update
    c = @channelsCombo
    if c.numberOfItems > 0
      sel = c.selectedItem
      if sel && !sel.title.to_s.empty?
        @joinButton.setEnabled(true)
        return
      end
    end
    @joinButton.setEnabled(false)
  end
end
