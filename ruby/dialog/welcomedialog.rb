# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'dialoghelper'

class WelcomeDialog < NSObject
  include DialogHelper
  attr_accessor :delegate, :prefix
  ib_outlet :window, :nickText, :serverCombo, :channelTable, :autoConnectCheck
  ib_outlet :okButton, :addChannelButton, :deleteChannelButton
  
  def initialize
    @prefix = 'welcomeDialog'
    @channels = []
  end
  
  def start
    NSBundle.loadNibNamed_owner('WelcomeDialog', self)
    tableViewSelectionIsChanging(nil)
    @channelTable.text_delegate = self
    ServerDialog.servers.each {|i| @serverCombo.addItemWithObjectValue(i) }
    load
    update_ok_button
    show
  end
  
  def show
    unless @window.isVisible
      @window.centerOfScreen
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
  
  ib_action :onOk
  def onOk(sender)
    @channels.uniq!
    @channels.delete('')
    @channels.map! do |i|
      i.channelname? ? i : '#' + i
    end
    c = {
      :nick => @nickText.stringValue.to_s,
      :host => @serverCombo.stringValue.to_s,
      :channels => @channels,
      :auto_connect => @autoConnectCheck.state.to_i != 0,
    }
    fire_event('onOk', c)
    @window.close
  end
  
  ib_action :onCancel
  def onCancel(sender)
    @window.close
  end
  
  ib_action :onAddChannel
  def onAddChannel(sender)
    @channels << ''
    @channelTable.reloadData
    @channelTable.editColumn_row_withEvent_select(0, @channels.size-1, nil, true)
  end

  ib_action :onDeleteChannel
  def onDeleteChannel(sender)
    n = @channelTable.selectedRows[0]
    if n
      @channels.delete_at(n)
      @channelTable.reloadData
    end
  end
  
  def numberOfRowsInTableView(sender)
    @channels.size
  end
  
  def tableView_objectValueForTableColumn_row(sender, col, row)
    @channels[row]
  end
  
  def tableViewSelectionIsChanging(note)
    @deleteChannelButton.setEnabled(!@channelTable.selectedRows.empty?)
  end
  
  def textDidEndEditing(note)
    n = @channelTable.editedRow
    if n >= 0
      @channels[n] = note.object.textStorage.string.to_s
      @channelTable.reloadData
      @channelTable.select(n)
    end
  end
  
  def controlTextDidChange(note)
    update_ok_button
  end
  
  ib_action :onServerComboChanged
  def onServerComboChanged(sender)
    update_ok_button
  end
  
  private
  
  def load
    nick = OSX::NSUserName().gsub(/\s/, '')
    if /\A[a-z][-_a-z\d]*\z/i =~ nick
      @nickText.setStringValue(nick)
    end
  end
  
  def update_ok_button
    nick = @nickText.stringValue.to_s
    server = @serverCombo.stringValue.to_s
    @okButton.setEnabled(!nick.empty? && !server.empty?)
  end
end
