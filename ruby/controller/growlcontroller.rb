# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

class GrowlController
  attr_accessor :owner
  
  GROWL_LOGIN_MSG = "Logged in"
  GROWL_DISCONNECT_MSG = "Disconnected"
  GROWL_HIGHLIGHT = "Highlight message received"
  GROWL_NEW_TALK = "New talk started"
  GROWL_CHANNEL_MSG = "Channel message received"
  GROWL_TALK_MSG = "Talk message received"
  GROWL_KICKED_MSG = "Kicked out from channel"
  GROWL_INVITED_MSG = "Invited to channel"
  GROWL_FILE_RECEIVE_REQUEST_MSG = "File receive requested"
  GROWL_FILE_RECEIVE_SUCCEEDED_MSG = "File receive succeeded"
  GROWL_FILE_RECEIVE_FAILED_MSG = "File receive failed"
  GROWL_FILE_SEND_SUCCEEDED_MSG = "File send succeeded"
  GROWL_FILE_SEND_FAILED_MSG = "File send failed"

  def register
    return if @growl
    @growl = Growl::Notifier.sharedInstance
    @growl.delegate = self
    all = [GROWL_LOGIN_MSG, GROWL_DISCONNECT_MSG, GROWL_HIGHLIGHT, GROWL_NEW_TALK, GROWL_CHANNEL_MSG, GROWL_TALK_MSG, GROWL_KICKED_MSG, GROWL_INVITED_MSG,
            GROWL_FILE_RECEIVE_REQUEST_MSG, GROWL_FILE_RECEIVE_SUCCEEDED_MSG, GROWL_FILE_RECEIVE_FAILED_MSG,
            GROWL_FILE_SEND_SUCCEEDED_MSG, GROWL_FILE_SEND_FAILED_MSG]
    default = [GROWL_HIGHLIGHT, GROWL_NEW_TALK]
    @growl.register(:LimeChat, all, default)
  end
  
  def notify(kind, title, desc, context=nil)
    priority = :normal
    sticky = false
    
    case kind
    when :highlight
      kind = GROWL_HIGHLIGHT
      priority = :high
      sticky = true
      title = "Highlight: #{title}"
    when :newtalk
      kind = GROWL_NEW_TALK
      priority = :high
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
    when :file_receive_request
      kind = GROWL_FILE_RECEIVE_REQUEST_MSG
      priority = :high
      sticky = true
      desc = "From #{title}\n#{desc}"
      title = "File receive request"
      context = 'dcc'
    when :file_receive_succeeded
      kind = GROWL_FILE_RECEIVE_SUCCEEDED_MSG
      desc = "From #{title}\n#{desc}"
      title = "File receive succeeded"
      context = 'dcc'
    when :file_receive_failed
      kind = GROWL_FILE_RECEIVE_FAILED_MSG
      desc = "From #{title}\n#{desc}"
      title = "File receive failed"
      context = 'dcc'
    when :file_send_succeeded
      kind = GROWL_FILE_SEND_SUCCEEDED_MSG
      desc = "To #{title}\n#{desc}"
      title = "File send succeeded"
      context = 'dcc'
    when :file_send_failed
      kind = GROWL_FILE_SEND_FAILED_MSG
      desc = "To #{title}\n#{desc}"
      title = "File send failed"
      context = 'dcc'
    end
    
    @growl.notify(kind, title, desc, :click_context => context, :sticky => sticky, :priority => priority)
  end

  def growlNotifier_notificationClicked(sender, context)
    @owner.window.makeKeyAndOrderFront(nil)
    NSApp.activateIgnoringOtherApps(true)
    
    if context == 'dcc'
      @owner.dcc.show(true)
    elsif /\A(\d+)[^\d](\d+)\z/ =~ context
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
