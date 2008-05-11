# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

class TreeView < NSOutlineView
  attr_accessor :key_delegate
  
  def countSelectedRows
    selectedRowIndexes.count.to_i
  end

  def selectedRows
    selectedRowIndexes.to_a
  end
  
  def select(index, scroll=true)
    selectRowIndexes_byExtendingSelection([index].to_indexset, false)
    scrollRowToVisible(index) if scroll
  end
  
  def menuForEvent(event)
    p = convertPoint_fromView(event.locationInWindow, nil)
    i = rowAtPoint(p)
    if i >= 0
      select(i)
    end
    menu
  end
  
  def setFont(font)
    tableColumns.to_a.each {|i| i.dataCell.setFont(font)}
    f = frame
    f.height = 1e+37
    f.height = tableColumns.to_a[0].dataCell.cellSizeForBounds(f).height.ceil
    setRowHeight(f.height)
    setNeedsDisplay(true)
  end
  
  def font
    tableColumns.to_a[0].dataCell.font
  end
  
  def keyDown(e)
    if @key_delegate
      case e.keyCode
      when 123..126 # cursor keys
      when 116,121  # page up/down
      else
        if @key_delegate.respond_to?(:treeView_keyDown)
          @key_delegate.treeView_keyDown(e)
          return
        end
      end
    end
    super_keyDown(e)
  end
end
