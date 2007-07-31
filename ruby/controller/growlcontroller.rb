# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

class GrowlController
  include OSX
  attr_accessor :owner
  
  GROWL_LOGIN_MSG = "Logged in"
  GROWL_DISCONNECT_MSG = "Disconnected"
  GROWL_HIGHLIGHT = "Highlight message received"
  GROWL_NEW_TALK = "New talk started"
  GROWL_CHANNEL_MSG = "Channel message received"
  GROWL_TALK_MSG = "Talk message received"
  GROWL_KICKED_MSG = "Kicked out from channel"
  GROWL_INVITED_MSG = "Invited to channel"

  def register
    return if @growl
    @growl = Growl::Notifier.alloc.initWithDelegate(self)
    all = [GROWL_LOGIN_MSG, GROWL_DISCONNECT_MSG, GROWL_HIGHLIGHT, GROWL_NEW_TALK, GROWL_CHANNEL_MSG, GROWL_TALK_MSG, GROWL_KICKED_MSG, GROWL_INVITED_MSG]
    default = [GROWL_HIGHLIGHT, GROWL_NEW_TALK]
    @growl.start(:LimeChat, all, default)
  end
  
  def notify(kind, title, desc, context)
    return if NSApp.isActive?
    
    priority = 0
    sticky = false
    
    case kind
    when :highlight
      kind = GROWL_HIGHLIGHT
      priority = 2
      sticky = true
      title = "Highlight: #{title}"
    when :newtalk
      kind = GROWL_NEW_TALK
      priority = 1
      sticky = true
      title = "New Talk: #{title}"
    when :channeltext
      kind = GROWL_CHANNEL_MSG
    when :talktext
      kind = GROWL_TALK_MSG
      title = "Talk: #{title}"
    when :kicked
      kind = GROWL_KICKED_MSG
      title = "Kicked: #{title}"
    when :invited
      kind = GROWL_INVITED_MSG
      title = "Invited: #{title}"
    when :login
      kind = GROWL_LOGIN_MSG
      title = "Logged in: #{title}"
    when :disconnect
      kind = GROWL_DISCONNECT_MSG
      title = "Disconnected: #{title}"
    end
    
    @growl.notify(kind, title, desc, context, sticky, priority)
  end

  def growl_onClicked(sender, context)
    NSApp.activateIgnoringOtherApps(true)
    
    if /\A(\d+)[^\d](\d+)\z/ =~ context
      uid = $1.to_i
      cid = $2.to_i
      u, c = @owner.find_by_id(uid, cid)
      if c
        @owner.select(c)
      elsif u
        @owner.select(u)
      end
    elsif /\A(\d+)\z/ =~ context
      uid = $1.to_i
      u = @owner.find_unit_by_id(uid)
      @owner.select(u) if u
    end
  end
end
