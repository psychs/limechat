# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'dialoghelper'

class ServerDialog < OSX::NSObject
  include OSX
  include DialogHelper  
  attr_accessor :window
  attr_accessor :delegate, :prefix
  attr_reader :uid
  ib_mapped_outlet :nameText, :hostCombo, :passwordText, :nickText, :usernameText, :realnameText, :encodingCombo, :auto_connectCheck
  ib_mapped_int_outlet :portText
  ib_outlet :leaveCommentText, :userinfoText, :invisibleCheck, :loosenNickLengthCheck, :nickLengthText
  ib_outlet :channelsTable
  ib_outlet :okButton
  
  def initialize
    @prefix = 'serverDialog'
  end
  
  def config
    @c
  end
  
  def start(config, uid)
    @c = config
    @uid = uid
    NSBundle.loadNibNamed_owner('ServerDialog', self)
    @channelsTable.setTarget(self)
    @channelsTable.setDoubleAction('tableView_doubleClicked:')
    @window.setTitle("New Server") if uid < 0
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
    name = @nameText.stringValue.to_s
    host = @hostCombo.stringValue.to_s
    port = @portText.stringValue.to_s
    nick = @nickText.stringValue.to_s
    username = @usernameText.stringValue.to_s
    realname = @realnameText.stringValue.to_s
    @okButton.setEnabled(!name.empty? && !host.empty? && port.to_i > 0 && !nick.empty? && !username.empty? && !realname.empty?)
  end
  
  def numberOfRowsInTableView(sender)
    @c.channels.length
  end
  
  def tableView_objectValueForTableColumn_row(sender, col, row)
    i = @c.channels[row]
    col = col.identifier.to_s.to_sym
    case col
    when :name; i.name
    when :pass; i.password
    when :mode; i.mode
    when :topic; i.topic
    when :join; i.auto_join
    when :console; i.console
    when :highlight; i.keyword
    when :unread; i.unread
    end
  end
  
  def tableView_setObjectValue_forTableColumn_row(sender, obj, col, row)
    i = @c.channels[row]
    col = col.identifier.to_s.to_sym
    case col
    when :join; i.auto_join = obj.intValue != 0
    when :console; i.console = obj.intValue != 0
    when :highlight; i.keyword = obj.intValue != 0
    when :unread; i.unread = obj.intValue != 0
    end
  end
  
  def tableView_doubleClicked(sender)
    puts 'double click'
  end
end
