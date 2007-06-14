# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the same terms as Ruby.

require 'utility'

class DccManager < OSX::NSObject
  include OSX
  ib_outlet :window, :receiver_table, :sender_table
  
  def initialize
    @receivers = []
    @senders = []
  end
  
  def loadNib
    return if @loaded
    NSBundle.loadNibNamed_owner('DccDialog', self)
    @window.key_delegate = self
    @loaded = true
    @receiver_cell = FileReceiverCell.alloc.init
    col = @receiver_table.tableColumns[0]
    col.setDataCell(@receiver_cell)
    @receivers.each do |r|
      if r.status == :receiving
        dccreceiver_on_open(r)
      end
    end
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
  
  def add_receiver(i)
    i.delegate = self
    @receivers.unshift(i)
    reload_receiver_table
  end
  
  def add_sender(i)
    i.delegate = self
    @senders.unshift(i)
    reload_sender_table
  end
  
  def reload_receiver_table
    @receiver_table.reloadData if @loaded && @window.isVisible
  end
  
  def reload_sender_table
    @sender_table.reloadData if @loaded && @window.isVisible
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
      bar = NSProgressIndicator.alloc.init
      bar.setIndeterminate(false)
      bar.setMinValue(0)
      bar.setMaxValue(sender.size)
      bar.setDoubleValue(sender.received_size)
      @receiver_table.addSubview(bar)
      sender.progress_bar = bar
      reload_receiver_table
    end
  end
  
  def dccreceiver_on_close(sender)
    return unless @loaded
=begin
    bar = sender.progress_bar
    if bar
      sender.progress_bar = nil
      bar.removeFromSuperview
      reload_receiver_table
    end
=end
    reload_receiver_table
  end
  
  
  # table
  
  def numberOfRowsInTableView(sender)
    if sender.__ocid__ == @receiver_table.__ocid__
      @receivers.length
    else
      @senders.length
    end
  end
  
  def tableView_objectValueForTableColumn_row(sender, col, row)
    if sender.__ocid__ == @receiver_table.__ocid__
      i = @receivers[row.to_i]
      cell = col.dataCell
      cell.setStringValue(i.filename)
      cell.setHighlighted(@receiver_table.isRowSelected(row))
      cell.sender_nick = i.sender_nick
      cell.size = i.size
      cell.received_size = i.received_size
      cell.speed = i.speed
      cell.time_remaining = i.speed > 0 ? (i.size - i.received_size) / i.speed : nil
      
      ext = File.extname(i.filename)
      ext = $1 if /\A\.?(.+)\z/ =~ ext
      cell.setImage(NSWorkspace.sharedWorkspace.iconForFileType(ext))
      cell.progress_bar = i.progress_bar if i.progress_bar
      i.filename
    else
      ''
    end
  end
  
  # window
  
  def dialogWindow_onEscape
    @window.orderOut(self)
  end
end


class FileReceiverCell < OSX::NSCell
  include OSX
  attr_accessor :sender_nick, :received_size, :size, :speed, :time_remaining, :message
  attr_accessor :progress_bar
  
  FILENAME_HEIGHT = 20
  FILENAME_TOP_MARGIN = 1
  PROGRESSBAR_HEIGHT = 12
  STATUS_HEIGHT = 16
  STATUS_TOP_MARGIN = 1
  RIGHT_MARGIN = 10
  IMAGE_SIZE = NSSize.new(32, 32)
  
  def drawInteriorWithFrame_inView(frame, view)
    image = self.image
    if image
      size = IMAGE_SIZE
      margin = (frame.size.height - size.height) / 2
      pt = frame.origin.dup
      pt.x += margin
      pt.y += margin
      pt.y += size.height if view.isFlipped
      image.setSize(size)
      image.compositeToPoint_operation(pt, NSCompositeSourceOver)
    end
    
    offset = !!@progress_bar ? 0 : PROGRESSBAR_HEIGHT / 3
    
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
    end
    @progress_bar = nil
    
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
      NSForegroundColorAttributeName => self.isHighlighted ? NSColor.whiteColor : NSColor.grayColor
    }
    str = "From #{@sender_nick}    #{fsize(@received_size)} / #{fsize(@size)} (#{fsize(@speed)}/s)"
    if @time_remaining
      str += "  -- #{ftime(@time_remaining)} remaining"
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


module NumberFormat
  def self.format_time(sec)
    min = sec / 60
    sec %= 60
    hour = min / 60
    min %= 60
    if hour >= 1
      sprintf("%d:%02d:%02d", hour, min, sec)
    else
      sprintf("%d:%02d", min, sec)
    end
  end
  
  def self.format_size(bytes)
    kb = bytes / 1024.0
    mb = kb / 1024.0
    gb = mb / 1024.0
    if gb >= 1
      if gb >= 10
        sprintf("%d GB", gb)
      else
        sprintf("%1.1f GB", gb)
      end
    elsif mb >= 1
      if mb >= 10
        sprintf("%d MB", mb)
      else
        sprintf("%1.1f MB", mb)
      end
    else
      sprintf("%d KB", kb)
    end
  end
end
