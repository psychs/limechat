# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

class TreeView < OSX::NSOutlineView
  include OSX
  
  def countSelectedRows
    selectedRowIndexes.count.to_i
  end

  def selectedRows
    ary = []
    set = selectedRowIndexes
    i = set.firstIndex.to_i
    return ary if i == NSNotFound
    ary << i
    (set.count.to_i-1).times do
      i = set.indexGreaterThanIndex(i).to_i
      break if i == NSNotFound
      ary << i
    end
    ary
  end
  
  def select(index, scroll=true)
    self.selectRowIndexes_byExtendingSelection(NSIndexSet.indexSetWithIndex(index), false)
    self.scrollRowToVisible(index) if scroll
  end
  
  def menuForEvent(event)
    p = convertPoint_fromView(event.locationInWindow, nil)
    i = rowAtPoint(p)
    if i >= 0
      select(i)
    end
    self.menu
  end
end
