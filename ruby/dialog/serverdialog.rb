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
  ib_mapped_outlet :leaving_commentText, :userinfoText, :invisibleCheck
  ib_outlet :channelsTable, :addButton, :editButton, :deleteButton, :upButton, :downButton
  ib_outlet :okButton
  
  TABLE_ROW_TYPE = 'row'
  TABLE_ROW_TYPES = [TABLE_ROW_TYPE]
  
  def initialize
    @prefix = 'serverDialog'
  end
  
  def config
    @c
  end
  
  def start(conf, uid)
    @c = conf
    @uid = uid
    NSBundle.loadNibNamed_owner('ServerDialog', self)
    @channelsTable.setTarget(self)
    @channelsTable.setDoubleAction('tableView_doubleClicked:')
  	@channelsTable.registerForDraggedTypes(TABLE_ROW_TYPES);
    @window.setTitle("New Server") if uid < 0
    load
    update_connection_page
    update_channels_page
    show
  end
  
  def show
    @window.makeKeyAndOrderFront(self)
  end
  
  def close
    @channelsTable.unregisterDraggedTypes
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
    update_connection_page
  end
  
  def update_connection_page
    name = @nameText.stringValue.to_s
    host = @hostCombo.stringValue.to_s
    port = @portText.stringValue.to_s
    nick = @nickText.stringValue.to_s
    username = @usernameText.stringValue.to_s
    realname = @realnameText.stringValue.to_s
    @okButton.setEnabled(!name.empty? && !host.empty? && port.to_i > 0 && !nick.empty? && !username.empty? && !realname.empty?)
  end
  
  def update_channels_page
    t = @channelsTable
    sel = t.selectedRows[0]
    unless sel
      @editButton.setEnabled(false)
      @deleteButton.setEnabled(false)
      @upButton.setEnabled(false)
      @downButton.setEnabled(false)
    else
      @editButton.setEnabled(true)
      @deleteButton.setEnabled(true)
      if sel == 0
        @upButton.setEnabled(false)
        @downButton.setEnabled(true)
      elsif sel == @c.channels.length - 1
        @upButton.setEnabled(true)
        @downButton.setEnabled(false)
      else
        @upButton.setEnabled(true)
        @downButton.setEnabled(true)
      end
    end
  end
  
  def reload_table
    @channelsTable.reloadData
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
  
  def tableViewSelectionDidChange(n)
    update_channels_page
  end
  
  def tableView_doubleClicked(sender)
    onEdit(sender)
  end
  
  objc_method :tableView_writeRows_toPasteboard, 'c@:@@@'
  def tableView_writeRows_toPasteboard(sender, rows, pboard)
    pboard.declareTypes_owner(TABLE_ROW_TYPES, self)
    pboard.setPropertyList_forType(rows, TABLE_ROW_TYPE)
    true
  end
  
  def tableView_validateDrop_proposedRow_proposedDropOperation(sender, info, row, op)
  	pboard = info.draggingPasteboard
  	if op == NSTableViewDropAbove && pboard.availableTypeFromArray(TABLE_ROW_TYPES)
  	  NSDragOperationGeneric
	  else
	    NSDragOperationNone
    end
  end
  
  objc_method :tableView_acceptDrop_row_dropOperation, 'c@:@@ii'
  def tableView_acceptDrop_row_dropOperation(sender, info, row, op)
  	pboard = info.draggingPasteboard
  	return false unless op == NSTableViewDropAbove && pboard.availableTypeFromArray(TABLE_ROW_TYPES)
    ary = @c.channels
    sel = @channelsTable.selectedRows.map {|i| ary[i.to_i] }
    
    targets = pboard.propertyListForType(TABLE_ROW_TYPE).to_a.map {|i| ary[i.to_i] }
    high = ary[0...row] || []
    low = ary[row...ary.length] || []
    targets.each do |i|
      high.delete(i)
      low.delete(i)
    end
    @c.channels = high + targets + low

    unless sel.empty?
      sel = sel.map {|i| @c.channels.index(i) }
      @channelsTable.selectRows(sel)
    end
    reload_table
    true
  end

  def onAdd(sender)
    sel = @channelsTable.selectedRows[0]
    conf = sel ? @c.channels[sel] : IRCChannelConfig.new
    @sheet = ChannelDialog.alloc.init
    @sheet.delegate = self
    @sheet.start_sheet(@window, conf, true)
  end
  
  def onEdit(sender)
    sel = @channelsTable.selectedRows[0]
    return unless sel
    conf = @c.channels[sel]
    @sheet = ChannelDialog.alloc.init
    @sheet.delegate = self
    @sheet.start_sheet(@window, conf)
  end
  
  def channelDialog_onOk(sender, conf)
    i = @c.channels.index {|t| t.name == conf.name }
    if i
      @c.channels[i] = conf
    else
      @c.channels << conf
    end
    reload_table
    @sheet = nil
  end
  
  def channelDialog_onCancel(sender)
    @sheet = nil
  end
  
  def onDelete(sender)
    sel = @channelsTable.selectedRows[0]
    return unless sel
    @c.channels.delete_at(sel)
    count = @c.channels.length
    if count > 0
      if count <= sel
        @channelsTable.select(count - 1)
      else
        @channelsTable.select(sel)
      end
    end
    reload_table
  end
  
  def onUp(sender)
    sel = @channelsTable.selectedRows[0]
    return unless sel
    return if sel == 0
    i = @c.channels.delete_at(sel)
    sel -= 1
    @c.channels.insert(sel, i)
    @channelsTable.select(sel)
    reload_table
  end
  
  def onDown(sender)
    sel = @channelsTable.selectedRows[0]
    return unless sel
    return if sel == @c.channels.length - 1
    i = @c.channels.delete_at(sel)
    sel += 1
    @c.channels.insert(sel, i)
    @channelsTable.select(sel)
    reload_table
  end
end
