# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'dialoghelper'

class ListDialog < NSObject
  include DialogHelper
  attr_accessor :delegate, :prefix
  ib_outlet :window, :table, :updateButton, :closeButton, :searchText
  
  def initialize
    @prefix = 'listDialog'
    @list = []
    @flist = nil
    @filter = nil
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
      if @filter.nil?
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
    filter = sender.stringValue.to_s
    @filter = filter.empty? ? nil : Regexp.compile(Regexp.escape(filter), Regexp::IGNORECASE)
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
    @list.sort! do |a,b|
      row_compare a, b
    end
  end

  def sorted_insert(ary, item)
    # do a binary search
    # once the range hits a length of 5 (arbitrary)
    # switch to linear search
    head = 0
    tail = ary.size
    while tail - head > 5
      pivot = (head + tail) / 2
      if row_compare(ary[pivot], item) > 0
        tail = pivot
      else
        head = pivot
      end
    end
    head.upto(tail-1) do |idx|
      if row_compare(ary[idx], item) > 0
        ary.insert idx, item
        return
      end
    end
    ary.insert tail, item
  end

  def row_compare(a, b)
    if @sort_key == 1
      res = a[1] <=> b[1]
    else
      res = a[@sort_key].casecmp b[@sort_key]
    end
    if res == 0
      if @sort_key == 0
        res = a[1] <=> b[1]
      else
        res = a[0].casecmp b[0]
      end
    end
    if @sort_order == :ascent
      res
    else
      - res
    end
  end
  
  def add_item(item)
    sorted_insert @list, item
    sorted_insert @flist, item if item_matches_filter?(item) unless @flist.nil?
    note_number_of_rows_changed
  end
  
  def reload_table
    @table.reloadData
  end

  def note_number_of_rows_changed
    @table.noteNumberOfRowsChanged
  end
  
  def build_filtered_list
    return if @flist
    @flist = @list.select {|i| item_matches_filter?(i) }
  end

  def item_matches_filter?(row)
    row[0] =~ @filter || row[2] =~ @filter
  end
  
  def numberOfRowsInTableView(sender)
    if @filter.nil?
      @list.size
    else
      build_filtered_list
      @flist.size
    end
  end
  
  def tableView_objectValueForTableColumn_row(sender, col, row)
    if @filter.nil?
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
    if c = preferences.load_window('channel_list_window')
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
      preferences.save_window('channel_list_window', c)
    end
  end
end
