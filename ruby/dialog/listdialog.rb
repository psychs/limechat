# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'dialoghelper'

class ListDialog < NSObject
  include DialogHelper
  attr_accessor :delegate, :prefix, :pref
  ib_outlet :window, :table, :updateButton, :closeButton, :searchText
  
  def initialize
    @prefix = 'listDialog'
    @list = []
    @flist = nil
    @filter = ''
    @sort_key = 1
    @sort_order = :descent
  end
  
  def start
    NSBundle.loadNibNamed_owner('ListDialog', self)
    load_window_state
    @table.setDoubleAction(:onJoin)
    @window.makeFirstResponder(@updateButton)
    show
  end
  
  def show
    @window.setTitle("Channel List - #{@delegate.name}")
    @window.makeKeyAndOrderFront(self)
  end
  
  def close
    @delegate = nil
    @window.close
  end
  
  def windowWillClose(sender)
    save_window_state
    fire_event('onClose')
  end
  
  ib_action :onClose
  def onClose(sender)
    @window.close
  end
  
  ib_action :onUpdate
  def onUpdate(sender)
    fire_event('onUpdate')
  end
  
  ib_action :onJoin
  def onJoin(sender)
    i = @table.selectedRows[0]
    if i
      if @filter.empty?
        list = @list
      else
        build_filtered_list
        list = @flist
      end
      item = list[i]
      if item
        fire_event('onJoin', item[0])
      end
    end
  end
  
  ib_action :onSearchTextChanged
  def onSearchTextChanged(sender)
    @filter = sender.stringValue.to_s
    @flist = nil
    reload_table
  end
  
  def tableView_didClickTableColumn(table, col)
    i = case col.identifier
      when 'chname'; 0
      when 'count'; 1
      else; 2
    end
    if @sort_key == i
      @sort_order = @sort_order == :ascent ? :descent : :ascent
    else
      @sort_key = i
      @sort_order = :ascent
    end
    @flist = nil
    sort
    reload_table
  end
  
  def clear
    @list = []
    @flist = nil
    reload_table
  end
  
  def sort
    @list = @list.sort do |a,b|
      if @sort_key == 1
        res = a[1] <=> b[1]
      else
        res = a[@sort_key].downcase <=> b[@sort_key].downcase
      end
      if res == 0
        if @sort_key == 0
          res = a[1] <=> b[1]
        else
          res = a[0].downcase <=> b[0].downcase
        end
      else
        if @sort_order == :ascent
          res
        else
          - res
        end
      end
    end
  end
  
  def add_item(item)
    @list << item
    @flist = nil
    if @list.size % 200 == 0
      sort
      reload_table
    end
  end
  
  def reload_table
    @table.reloadData
  end
  
  def build_filtered_list
    return if @flist
    pattern = /#{Regexp.escape(@filter)}/i
    @flist = @list.select {|i| i[0] =~ pattern || i[2] =~ pattern}
  end
  
  def numberOfRowsInTableView(sender)
    if @filter.empty?
      @list.size
    else
      build_filtered_list
      @flist.size
    end
  end
  
  def tableView_objectValueForTableColumn_row(sender, col, row)
    if @filter.empty?
      list = @list
    else
      build_filtered_list
      list = @flist
    end
    
    m = list[row]
    case col.identifier
      when 'chname'; m[0]
      when 'count'; m[1].to_s
      else; m[2]
    end
  end
  
  private

  def load_window_state
    c = @pref.load_window('channel_list_window')
    if c
      frame = NSRect.from_dic(c[:window])
      set_table_header_settings(@table, c[:tablecols])
    else
      frame = NSRect.from_center(NSScreen.screens[0].visibleFrame.center, 500, 400)
    end
    @window.setFrame_display(frame, false)
  end

  def save_window_state
    if @window
      c = {
        :window => @window.frame.to_dic,
        :tablecols => get_table_header_settings(@table),
      }
      @pref.save_window('channel_list_window', c)
    end
  end
end
