# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'utility'
require 'numberformat'

class DccManager < OSX::NSObject
  include OSX
  attr_accessor :pref, :world
  ib_outlet :window, :splitter, :receiver_table, :sender_table, :clear_button
  
  def initialize
    @receivers = []
    @senders = []
  end
  
  def loadNib
    return if @loaded
    NSBundle.loadNibNamed_owner('DccDialog', self)
    @window.key_delegate = self
    @loaded = true
    @splitter.setFixedViewIndex(1)
    @receiver_cell = FileTransferCell.alloc.init
    @receiver_cell.op = :receive
    @receiver_table.tableColumns[0].setDataCell(@receiver_cell)
    @sender_cell = FileTransferCell.alloc.init
    @sender_cell.op = :send
    @sender_table.tableColumns[0].setDataCell(@sender_cell)
    @receivers.each do |r|
      if r.status == :receiving
        dccreceiver_on_open(r)
      end
    end
    @senders.each do |s|
      if s.status == :sending
        dccsender_on_connect(s)
      end
    end
    load_window_state
  end
  
  def show
    loadNib
    @window.makeKeyAndOrderFront(self)
    reload_receiver_table
    reload_sender_table
  end
  
  def close
    @window.orderOut(self)
  end
  
  def onClear(sender)
    sel = @receivers.select {|i| i.status == :error || i.status == :stop || i.status == :complete}
    sel.each {|i| delete_receiver(i)}
    sel = @senders.select {|i| i.status == :error || i.status == :stop || i.status == :complete}
    sel.each {|i| delete_sender(i)}
    reload_receiver_table
    reload_sender_table
  end
  
  def delete_receiver(i)
    i.close
    bar = i.progress_bar
    bar.removeFromSuperview if bar
    @receivers.delete(i)
  end
  
  def delete_sender(i)
    i.close
    bar = i.progress_bar
    bar.removeFromSuperview if bar
    @senders.delete(i)
  end

  # menu

  def validateMenuItem(i)
    if i.tag < 3100
      return false if @receiver_table.countSelectedRows == 0
      sel = @receiver_table.selectedRows
      sel = sel.map {|e| @receivers[e]}
      case i.tag
      when 3001 #start
        !!sel.find {|e| e.status == :waiting || e.status == :error}
      when 3002 #resume
        true
      when 3003 #stop
        !!sel.find {|e| e.status == :connecting || e.status == :receiving}
      when 3004 #delete
        true
      else
        false
      end
    else
      return false if @sender_table.countSelectedRows == 0
      sel = @sender_table.selectedRows
      sel = sel.map {|e| @senders[e]}
      case i.tag
      when 3101 #start
        !!sel.find {|e| e.status == :waiting || e.status == :error || e.status == :stop}
      when 3102 #stop
        !!sel.find {|e| e.status == :listening || e.status == :sending}
      when 3103 #delete
        true
      else
        false
      end
    end
  end
  
  def startReceiver(sender)
    sel = @receiver_table.selectedRows
    sel = sel.map {|i| @receivers[i]}
    sel.each {|i| i.open}
    reload_receiver_table
  end
  
  def stopReceiver(sender)
    sel = @receiver_table.selectedRows
    sel = sel.map {|i| @receivers[i]}
    sel.each {|i| i.close}
    reload_receiver_table
  end
  
  def deleteReceiver(sender)
    sel = @receiver_table.selectedRows
    sel = sel.map {|i| @receivers[i]}
    sel.each {|i| delete_receiver(i)}
    reload_receiver_table
  end
  
  def startSender(sender)
    sel = @sender_table.selectedRows
    sel = sel.map {|i| @senders[i]}
    sel.each do |i|
      u = @world.find_unit_by_id(i.uid)
      unless u && u.myaddress
        i.set_address_error
        next
      end
      i.open
    end
    reload_sender_table
  end
  
  def stopSender(sender)
    sel = @sender_table.selectedRows
    sel = sel.map {|i| @senders[i]}
    sel.each {|i| i.close}
    reload_sender_table
  end
  
  def deleteSender(sender)
    sel = @sender_table.selectedRows
    sel = sel.map {|i| @senders[i]}
    sel.each {|i| delete_sender(i)}
    reload_sender_table
  end

  # items
  
  def add_receiver(uid, nick, host, port, path, fname, size, ver)
    c = DccReceiver.new
    c.delegate = self
    c.uid = uid
    c.peer_nick = nick
    c.host = host
    c.port = port
    c.path = path
    c.filename = fname
    c.size = size
    c.version = ver
    ext = File.extname(c.filename)
    ext = $1 if /\A\.?(.+)\z/ =~ ext
    c.icon = NSWorkspace.sharedWorkspace.iconForFileType(ext)
    @receivers.unshift(c)
    
    #c.open
    reload_receiver_table
    show
  end
  
  def add_sender(uid, nick, file)
    c = DccSender.new
    c.pref = @pref
    c.delegate = self
    c.uid = uid
    c.peer_nick = nick
    c.full_filename = file
    ext = File.extname(c.filename)
    ext = $1 if /\A\.?(.+)\z/ =~ ext
    c.icon = NSWorkspace.sharedWorkspace.iconForFileType(ext)
    @senders.unshift(c)
    
    u = @world.find_unit_by_id(uid)
    unless u && u.myaddress
      c.set_address_error
      return
    end
    c.open
    
    reload_sender_table
    show
  end
  
  def reload_receiver_table
    return unless @loaded && @window.isVisible
    @receiver_table.reloadData
    update_clear_button
  end
  
  def reload_sender_table
    return unless @loaded && @window.isVisible
    @sender_table.reloadData
    update_clear_button
  end
  
  def update_clear_button
    rsel = @receivers.find {|i| i.status == :error || i.status == :stop || i.status == :complete}
    ssel = @senders.find {|i| i.status == :error || i.status == :stop || i.status == :complete}
    @clear_button.setEnabled(!!(rsel || ssel))
  end
  
  def on_timer
    @receivers.each {|i| i.on_timer }
    @senders.each {|i| i.on_timer }
    reload_receiver_table
    reload_sender_table
  end
  
  def dccreceiver_on_change(sender)
    reload_receiver_table
  end
  
  def dccsender_on_change(sender)
    reload_sender_table
  end
  
  def dccreceiver_on_open(sender)
    return unless @loaded
    unless sender.progress_bar
      bar = TableProgressIndicator.alloc.init
      #bar.setUsesThreadedAnimation(true)
      bar.setIndeterminate(false)
      bar.setMinValue(0)
      bar.setMaxValue(sender.size)
      bar.setDoubleValue(sender.processed_size)
      @receiver_table.addSubview(bar)
      sender.progress_bar = bar
      reload_receiver_table
    end
  end
  
  def dccreceiver_on_close(sender)
    return unless @loaded
    bar = sender.progress_bar
    if bar
      sender.progress_bar = nil
      bar.removeFromSuperview
    end
    reload_receiver_table
  end
  
  
  def dccsender_on_listen(s)
    u = @world.find_unit_by_id(s.uid)
    return unless u
    u.send_file(s.peer_nick, s.port, s.filename, s.size)
  end
  
  def dccsender_on_connect(sender)
    return unless @loaded
    unless sender.progress_bar
      bar = TableProgressIndicator.alloc.init
      #bar.setUsesThreadedAnimation(true)
      bar.setIndeterminate(false)
      bar.setMinValue(0)
      bar.setMaxValue(sender.size)
      bar.setDoubleValue(sender.processed_size)
      @sender_table.addSubview(bar)
      sender.progress_bar = bar
      reload_sender_table
    end
  end
  
  def dccsender_on_close(sender)
    return unless @loaded
    bar = sender.progress_bar
    if bar
      sender.progress_bar = nil
      bar.removeFromSuperview
    end
    reload_sender_table
  end
  
  
  # table
  
  def numberOfRowsInTableView(sender)
    if sender == @receiver_table
      @receivers.length
    else
      @senders.length
    end
  end
  
  def tableView_objectValueForTableColumn_row(sender, col, row)
    list = sender == @receiver_table ? @receivers : @senders
    i = list[row.to_i]
    cell = col.dataCell
    cell.setStringValue(i.filename)
    cell.setHighlighted(sender.isRowSelected(row))
    cell.peer_nick = i.peer_nick
    cell.size = i.size
    cell.processed_size = i.processed_size
    cell.speed = i.speed
    cell.time_remaining = i.speed > 0 ? (i.size - i.processed_size) / i.speed : nil
    cell.status = i.status
    cell.error = i.error
    cell.icon = i.icon
    cell.progress_bar = i.progress_bar
    i.filename
  end
  
  # window
  
  def dialogWindow_onEscape
    @window.orderOut(self)
  end

  def load_window_state
    win = @pref.load_window('dcc_window')
    if win
      f = NSRect.from_dic(win)
      @window.setFrame_display(f, true)
      @splitter.setPosition(win[:split])
    else
      @splitter.setPosition(150)
    end
  end

  def save_window_state
    return unless @loaded
    win = @window.frame.to_dic
    win.merge! :split => @splitter.position
    @pref.save_window('dcc_window', win)
  end
end


class FileTransferCell < OSX::NSCell
  include OSX
  attr_accessor :peer_nick, :processed_size, :size, :speed, :time_remaining, :status, :error
  attr_accessor :progress_bar, :icon, :op
  
  FILENAME_HEIGHT = 20
  FILENAME_TOP_MARGIN = 1
  PROGRESSBAR_HEIGHT = 12
  STATUS_HEIGHT = 16
  STATUS_TOP_MARGIN = 1
  RIGHT_MARGIN = 10
  ICON_SIZE = NSSize.new(32, 32)
  
  def drawInteriorWithFrame_inView(frame, view)
    if @icon
      size = ICON_SIZE
      margin = (frame.size.height - size.height) / 2
      pt = frame.origin.dup
      pt.x += margin
      pt.y += margin
      pt.y += size.height if view.isFlipped
      @icon.setSize(size)
      @icon.compositeToPoint_operation(pt, NSCompositeSourceOver)
      @icon = nil
    end
    
    offset = @progress_bar ? 0 : PROGRESSBAR_HEIGHT / 3
    
    fname = self.stringValue
    rect = frame.dup
    rect.origin.x += rect.size.height
    rect.origin.y += FILENAME_TOP_MARGIN + offset
    rect.size.width -= rect.size.height + RIGHT_MARGIN
    rect.size.height = FILENAME_HEIGHT - FILENAME_TOP_MARGIN
    style = NSMutableParagraphStyle.alloc.init
    style.setAlignment(NSLeftTextAlignment)
    style.setLineBreakMode(NSLineBreakByTruncatingMiddle)
    attrs = {
      NSParagraphStyleAttributeName => style,
      NSFontAttributeName => NSFont.fontWithName_size('Helvetica', 12),
      NSForegroundColorAttributeName => self.isHighlighted ? NSColor.whiteColor : NSColor.blackColor
    }
    fname.drawInRect_withAttributes(rect, attrs)

    if @progress_bar
      bar = @progress_bar
      rect = frame.dup
      rect.origin.x += rect.size.height
      rect.origin.y += FILENAME_HEIGHT
      rect.size.width -= rect.size.height + RIGHT_MARGIN
      rect.size.height = PROGRESSBAR_HEIGHT
      bar.setFrame(rect)
      @progress_bar = nil
    end
    
    rect = frame.dup
    rect.origin.x += rect.size.height
    rect.origin.y += FILENAME_HEIGHT + PROGRESSBAR_HEIGHT + STATUS_TOP_MARGIN - offset
    rect.size.width -= rect.size.height + RIGHT_MARGIN
    rect.size.height = STATUS_HEIGHT - STATUS_TOP_MARGIN
    style = NSMutableParagraphStyle.alloc.init
    style.setAlignment(NSLeftTextAlignment)
    style.setLineBreakMode(NSLineBreakByTruncatingTail)
    attrs = {
      NSParagraphStyleAttributeName => style,
      NSFontAttributeName => NSFont.fontWithName_size('Helvetica', 11),
      NSForegroundColorAttributeName =>
        if @status == :error
          NSColor.redColor
        elsif @status == :complete
          NSColor.blueColor
        elsif self.isHighlighted
          NSColor.whiteColor
        else
          NSColor.grayColor
        end
    }
    
    if @op == :send
      str = "To #{@peer_nick}    "
    else
      str = "From #{@peer_nick}    "
    end
    
    case @status
    when :waiting
      str += "#{fsize(@size)}"
    when :listening
      str += "#{fsize(@size)}  -- Requesting"
    when :sending,:receiving
      str += "#{fsize(@processed_size)} / #{fsize(@size)} (#{fsize(@speed)}/s)"
      if @time_remaining
        str += "  -- #{ftime(@time_remaining)} remaining"
      end
    when :stop
      str += "#{fsize(@processed_size)} / #{fsize(@size)}  -- Stopped"
    when :error
      str += "#{fsize(@processed_size)} / #{fsize(@size)}  -- Error: #{@error}"
    when :complete
      str += "#{fsize(@size)}  -- Complete"
    end
    
    NSString.stringWithString(str).drawInRect_withAttributes(rect, attrs)
  end
  
  def fsize(size)
    NumberFormat.format_size(size)
  end
  
  def ftime(sec)
    NumberFormat.format_time(sec)
  end
end
