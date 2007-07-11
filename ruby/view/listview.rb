# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

class ListView < OSX::NSTableView
  include OSX
  attr_accessor :key_delegate
  
  def keyDown(e)
    if @key_delegate
      case e.keyCode
      when 123..126 # cursor keys
      when 116,121  # page up/down
      else
        @key_delegate.listView_keyDown(e)
        return
      end
    end
    super_keyDown(e)
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
  
  def select(index, extendSelection=false)
    selectRowIndexes_byExtendingSelection(NSIndexSet.indexSetWithIndex(index), extendSelection)
  end
  
  def selectRows(indices, extendSelection=false)
    set = NSMutableIndexSet.alloc.init
    indices.each {|i| set.addIndex(i) }
    selectRowIndexes_byExtendingSelection(set, extendSelection)
  end
  
  def countSelectedRows
    selectedRowIndexes.count.to_i
  end
  
  def rightMouseDown(event)
    p = convertPoint_fromView(event.locationInWindow, nil)
    i = rowAtPoint(p)
    if i >= 0
      unless selectedRowIndexes.containsIndex(i)
        select(i)
      end
    else
      #deselectAll(self)
    end
    super_rightMouseDown(event)
  end
end
